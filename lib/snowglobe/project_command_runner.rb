require "bundler"

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
        runner.add_env("TESTOPTS" => "-v")
      end
    end

    def run_rspec_tests(&block)
      run("rspec", &block)
    end
    alias_method :run_rspec_test_suite, :run_rspec_tests

    def run_rake_tasks!(*args, **options, &block)
      run_rake_tasks(
        *args,
        **options,
        run_successfully: true,
        &block
      )
    end

    def run_rake_tasks(*tasks, **options, &block)
      run("rake", *tasks, "--trace", **options, &block)
    end

    def run_inside_of_bundle!(*args, **options, &block)
      run(
        *args,
        **options,
        run_successfully: true,
        &block
      )
    end
    alias_method :run!, :run_inside_of_bundle!

    def run_inside_of_bundle(*args, **options, &block)
      CommandRunner.run(
        *args,
        **options,
        directory: fs.project_directory,
        command_prefix: "bundle exec",
        env: { "BUNDLE_GEMFILE" => fs.find_in_project("Gemfile") },
        around_command: -> (run_command) do
          if Bundler.respond_to?(:with_unbundled_env)
            Bundler.with_unbundled_env(&run_command)
          else
            Bundler.with_clean_env(&run_command)
          end
        end,
        &block
      )
    end
    alias_method :run, :run_inside_of_bundle

    def run_outside_of_bundle!(*args, **options, &block)
      run_outside_of_bundle(*args, **options, run_successfully: true, &block)
    end

    def run_outside_of_bundle(*args, **options, &block)
      CommandRunner.run(
        *args,
        **options,
        directory: fs.project_directory,
        &block
      )
    end

    private

    attr_reader :fs
  end
end
