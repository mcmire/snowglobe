module Snowglobe
  class ProjectCommandRunner
    def initialize(fs)
      @fs = fs
    end

    def run_n_unit_tests(*paths, &block)
      run("ruby -I lib -I test", *paths, &block)
    end

    def run_n_unit_test_suite
      run_rake_tasks("test") do |runner|
        runner.env["TESTOPTS"] = "-v"
      end
    end

    def run_rspec_test_suite(&block)
      run("rspec", &block)
    end

    def run_rake_tasks!(*args, **options)
      run_rake_tasks(*args, **options) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run_rake_tasks(*tasks, **options, &block)
      run("rake", *tasks, "--trace", **options, &block)
    end

    def run!(*args, **options)
      run(*args, **options) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run(*args, **options)
      CommandRunner.run(*args, **options) do |runner|
        runner.directory = fs.project_directory
        runner.command_prefix = "bundle exec"
        runner.env["BUNDLE_GEMFILE"] = fs.find_in_project("Gemfile").to_s

        runner.around_command do |run_command|
          if Bundler.respond_to?(:with_unbundled_env)
            Bundler.with_unbundled_env(&run_command)
          else
            Bundler.with_clean_env(&run_command)
          end
        end

        yield runner if block_given?
      end
    end

    def run_outside_of_bundle!(*args, **options)
      run_outside_of_bundle(*args, **options) do |runner|
        runner.run_successfully = true
        yield runner if block_given?
      end
    end

    def run_outside_of_bundle(*args, **options)
      CommandRunner.run(*args, **options) do |runner|
        runner.directory = fs.project_directory
        yield runner if block_given?
      end
    end

    private

    attr_reader :fs
  end
end
