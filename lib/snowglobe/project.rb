require "forwardable"

require_relative "bundle"
require_relative "database"
require_relative "filesystem"
require_relative "project_command_runner"

module Snowglobe
  class Project
    extend Forwardable

    def self.create
      new.tap(&:create)
    end

    def_delegators :bundle, :add_gem
    def_delegators :fs, :append_to_file, :write_file
    def_delegators(
      :command_runner,
      :run,
      :run!,
      :run_rspec_tests,
      :run_rspec_test_suite,
      :run_n_unit_tests,
      :run_n_unit_test_suite
    )

    def initialize
      @fs = Filesystem.new
      @command_runner = ProjectCommandRunner.new(fs)
      @bundle = Bundle.new(fs: fs, command_runner: command_runner)
    end

    def create
      fs.clean
      generate
    end

    def directory
      fs.project_directory
    end

    protected

    attr_reader :fs, :command_runner, :bundle

    def generate
      raise NotImplementedError
    end
  end
end
