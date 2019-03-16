module Snowglobe
  class ProjectCommandRunner
    def initialize(fs)
      @fs = fs
    end

    def run_migrations!
      run_rake_tasks!(["db:drop", "db:create", "db:migrate"])
    end

    def run_n_unit_tests(*paths)
      run_command_within_bundle("ruby -I lib -I test", *paths)
    end

    def run_n_unit_test_suite
      run_rake_tasks("test", env: { TESTOPTS: "-v" })
    end

    def run_rake_tasks!(*args, **options, &block)
      run_rake_tasks(
        *args,
        **options,
        run_successfully: true,
        &block
      )
    end

    def run_rake_tasks(*tasks)
      options = tasks.last.is_a?(Hash) ? tasks.pop : {}
      args = ["bundle", "exec", "rake", *tasks, "--trace"] + [options]
      run(*args)
    end

    def run_within_bundle(*args)
      run(*args) do |runner|
        runner.command_prefix = "bundle exec"
        runner.env["BUNDLE_GEMFILE"] = fs.find_in_project("Gemfile").to_s

        runner.around_command do |run_command|
          Bundler.with_clean_env(&run_command)
        end

        yield runner if block_given?
      end
    end

    def run!(*args, **options, &block)
      CommandRunner.run!(
        *args,
        directory: fs.project_directory,
        **options,
        &block
      )
    end

    def run(*args, **options, &block)
      CommandRunner.run(
        *args,
        directory: fs.project_directory,
        **options,
        &block
      )
    end

    private

    attr_reader :fs
  end
end
