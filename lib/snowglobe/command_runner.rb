require "open3"
require "pp"
require "shellwords"
require "timeout"

require_relative "output_helpers"

module Snowglobe
  class CommandRunner
    def self.run(*args, **options, &block)
      new(*args, **options, &block).run
    end

    def self.run!(*args, **options, &block)
      new(*args, **options, run_successfully: true, &block).run
    end

    def initialize(
      *args,
      command_prefix: "",
      directory: Dir.pwd,
      env: {},
      run_quickly: false,
      run_successfully: false,
      timeout: 10,
      around_command: -> (block) { block.call }
    )
      @args = args
      @command_prefix = command_prefix
      @directory = directory
      @env = env
      @run_quickly = run_quickly
      @run_successfully = run_successfully
      @timeout = timeout
      @wrapper = around_command

      @already_run = false

      yield self if block_given?
    end

    def add_env(env)
      @env = env.merge(@env)
    end

    def formatted_command
      [formatted_env, Shellwords.join(command)]
        .reject(&:empty?)
        .join(" ")
    end

    def run
      if !already_run?
        @already_run = true

        possibly_running_quickly do
          run_with_debugging

          if run_successfully? && !success?
            fail!
          end
        end
      end

      self
    end

    def stdout
      run
      @stdout
    end

    def stderr
      run
      @stderr
    end

    def output
      run
      @output
    end

    def elided_output
      lines = output.split(/\n/)
      new_lines = lines[0..4]

      if lines.size > 10
        new_lines << "(...#{lines.size - 10} more lines...)"
      end

      new_lines << lines[-5..-1]
      new_lines.join("\n")
    end

    def success?
      exit_status == 0
    end

    def exit_status
      run
      @status.exitstatus
    end

    def fail!
      raise CommandFailedError.create(
        command: formatted_command,
        exit_status: exit_status,
        output: output
      )
    end

    def has_output?(expected_output)
      if expected_output.is_a?(Regexp)
        output =~ expected_output
      else
        output.include?(expected_output)
      end
    end

    def pretty_print(pp)
      attributes = { env: env, command: command }

      pp.object_group(self) do
        pp.seplist(attributes, -> { pp.text "," }) do |key, value|
          pp.breakable " "
          pp.group(1) do
            pp.text key.to_s
            pp.text ":"
            pp.breakable
            pp.pp value
          end
        end
      end
    end

    alias_method :inspect, :pretty_print_inspect

    private

    attr_reader(
      :args,
      :command_prefix,
      :directory,
      :env,
      :timeout,
      :wrapper
    )

    def already_run?
      @already_run
    end

    def run_quickly?
      @run_quickly
    end

    def run_successfully?
      @run_successfully
    end

    def possibly_running_quickly(&block)
      if run_quickly?
        begin
          Timeout.timeout(timeout, &block)
        rescue Timeout::Error
          raise CommandTimedOutError.create(
            command: formatted_command,
            timeout: timeout,
            output: output
          )
        end
      else
        yield
      end
    end

    def run_with_debugging
      debug { "\n\e[33mChanging to directory:\e[0m #{directory}" }
      debug { "\e[32mRunning command:\e[0m #{formatted_command}" }

      run_with_wrapper

      debug do
        "\n" + Snowglobe::OutputHelpers.bookended(output)
      end
    end

    def debugging_enabled?
      ENV["DEBUG_COMMANDS"] == "1"
    end

    def debug
      if debugging_enabled?
        puts yield
      end
    end

    def run_with_wrapper
      wrapper.call(method(:run_freely))
    end

    def run_freely
      @stdout = ""
      @stderr = ""
      @output = ""
      @status = nil

      Dir.chdir(directory) do
        Open3.popen3(normalized_env, *command) do |stdin, stdout, stderr, thread|
          stdin.close_write

          capture_output(
            stdout => lambda do |data|
              @stdout << data
              @output << data
            end,
            stderr => lambda do |data|
              @stderr << data
              @output << data
            end
          )

          @status = thread.value
        end
      end
    end

    def normalized_env
      env.transform_values(&:to_s)
    end

    def command
      ([command_prefix] + args)
        .flatten
        .flat_map { |word| Shellwords.split(word.to_s) }
    end

    # Copied from: <https://github.com/crowdworks/joumae-ruby/blob/master/lib/joumae/command.rb>
    # Also see:
    # * <https://gist.github.com/chrisn/7450808>
    # * <http://coldattic.info/post/63/>
    def capture_output(mapping)
      ios = mapping.keys

      until ios.empty?
        readable_ios, = IO.select(ios, [], [])
        ios_ready_for_eof_check = readable_ios

        # We can safely call `eof` without blocking against previously selected
        # IOs.
        ios_ready_for_eof_check.select(&:eof).each do |src|
          # `select`ing an IO which has reached EOF blocks forever.
          # So you have to delete such IO from the array of IOs to `select`.
          ios.delete(src)
        end

        break if ios.empty?

        readable_ios.each do |io|
          begin
            data = io.read_nonblock(1024)
            mapping.fetch(io).call(data)
          rescue EOFError
            ios.delete(io)
          end
        end

        ios_ready_for_eof_check = ios & readable_ios
      end
    end

    def formatted_env
      normalized_env.map { |key, value| "#{key}=#{value.inspect}" }.join(" ")
    end

    class CommandFailedError < StandardError
      def self.create(command:, exit_status:, output:, message: nil)
        allocate.tap do |error|
          error.command = command
          error.exit_status = exit_status
          error.output = output
          error.__send__(:initialize, message)
        end
      end

      attr_accessor :command, :exit_status, :output

      def initialize(message = nil)
        super(message || build_message)
      end

      private

      def build_message
        message = <<-MESSAGE
Command #{command.inspect} failed, exiting with status #{exit_status}.
        MESSAGE

        if output
          message << <<-MESSAGE
Output:
#{Snowglobe::OutputHelpers.bookended(output)}
          MESSAGE
        end

        message
      end
    end

    class CommandTimedOutError < StandardError
      def self.create(command:, timeout:, output:, message: nil)
        allocate.tap do |error|
          error.command = command
          error.timeout = timeout
          error.output = output
          error.__send__(:initialize, message)
        end
      end

      attr_accessor :command, :timeout, :output

      def initialize(message = nil)
        super(message || build_message)
      end

      private

      def build_message
        message = <<-MESSAGE
Command #{formatted_command.inspect} timed out after #{timeout} seconds.
        MESSAGE

        if output
          message << <<-MESSAGE
Output:
#{Snowglobe::OutputHelpers.bookended(output)}
          MESSAGE
        end

        message
      end
    end
  end
end
