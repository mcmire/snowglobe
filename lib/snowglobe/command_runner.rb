require "forwardable"
require "timeout"
require "shellwords"

module Snowglobe
  class CommandRunner
    extend Forwardable

    TimeoutError = Class.new(StandardError)

    def self.run(*args, **options, &block)
      new(*args, **options, &block).tap(&:call)
    end

    def self.run!(*args, **options, &block)
      run(*args, run_successfully: true, **options, &block)
    end

    attr_reader :status, :options, :env
    attr_accessor :command_prefix, :run_quickly, :run_successfully, :retries,
      :timeout

    def initialize(
      *args,
      env: {},
      directory: Dir.pwd,
      run_successfully: false,
      **options
    )
      @reader, @writer = IO.pipe
      @options = options.merge(err: [:child, :out], out: writer)

      @args = args
      @env = normalize_env(env)
      self.directory = directory
      @run_successfully = run_successfully

      @wrapper = ->(block) { block.call }
      @command_prefix = ""
      @run_quickly = false
      @retries = 1
      @num_times_run = 0
      @timeout = 20

      yield self if block_given?
    end

    def directory
      options[:chdir]
    end

    def directory=(directory)
      if directory.nil?
        raise ArgumentError, "Must provide a directory"
      end

      options[:chdir] = directory
    end

    def around_command(&block)
      @wrapper = block
    end

    def formatted_command
      [formatted_env, Shellwords.join(command)].
        reject(&:empty?).
        join(" ")
    end

    def call
      possibly_retrying do
        possibly_running_quickly do
          run_with_debugging

          if run_successfully && !success?
            fail!
          end
        end
      end

      self
    end

    def stop
      unless writer.closed?
        writer.close
      end
    end

    def output
      @_output ||= begin
        stop
        without_colors(reader.read)
      end
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

    def_delegators :status, :success?

    def exit_status
      status.exitstatus
    end

    def fail!
      raise <<-MESSAGE
Command #{formatted_command.inspect} exited with status #{exit_status}.
Output:
#{divider("START") + output + divider("END")}
      MESSAGE
    end

    def has_output?(expected_output)
      if expected_output.is_a?(Regexp)
        output =~ expected_output
      else
        output.include?(expected_output)
      end
    end

    protected

    attr_reader :args, :reader, :writer, :wrapper

    private

    def normalize_env(env)
      env.reduce({}) do |hash, (key, value)|
        hash.merge(key.to_s => value)
      end
    end

    def command
      ([command_prefix] + args).flatten.flat_map do |word|
        Shellwords.split(word)
      end
    end

    def formatted_env
      env.map { |key, value| "#{key}=#{value.inspect}" }.join(" ")
    end

    def run
      pid = spawn(env, *command, options)
      Process.waitpid(pid)
      @status = $?
    end

    def run_with_wrapper
      wrapper.call(method(:run))
    end

    def run_with_debugging
      debug { "\n\e[33mChanging to directory:\e[0m #{directory}" }
      debug { "\e[32mRunning command:\e[0m #{formatted_command}" }

      run_with_wrapper

      debug { "\n" + divider("START") + output + divider("END") }
    end

    def possibly_running_quickly(&block)
      if run_quickly
        begin
          Timeout.timeout(timeout, &block)
        rescue Timeout::Error
          stop

          message =
            "Command timed out after #{timeout} seconds: " +
            "#{formatted_command}\n" +
            "Output:\n" +
            output

          raise TimeoutError, message
        end
      else
        yield
      end
    end

    def possibly_retrying
      @num_times_run += 1
      yield
    rescue StandardError => error
      debug { "#{error.class}: #{error.message}" }

      if @num_times_run < @retries
        sleep @num_times_run
        retry
      else
        raise error
      end
    end

    def divider(title = "")
      total_length = 72
      start_length = 3

      string = ""
      string << ("-" * start_length)
      string << title
      string << "-" * (total_length - start_length - title.length)
      string << "\n"
      string
    end

    def without_colors(string)
      string.gsub(/\e\[\d+(?:;\d+)?m(.+?)\e\[0m/, '\1')
    end

    def debugging_enabled?
      ENV["DEBUG_COMMANDS"] == "1"
    end

    def debug
      if debugging_enabled?
        puts yield
      end
    end
  end
end
