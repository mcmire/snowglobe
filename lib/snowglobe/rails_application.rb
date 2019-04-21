require "forwardable"
require "yaml"

require_relative "bundle"
require_relative "database"
require_relative "filesystem"
require_relative "project_command_runner"

module Snowglobe
  class RailsApplication
    extend Forwardable

    def_delegators :bundle, :add_gem
    def_delegators :fs, :append_to_file, :write_file
    def_delegators :command_runner, :run_migrations!, :run_n_unit_test_suite

    def initialize
      @fs = Filesystem.new
      @command_runner = ProjectCommandRunner.new(fs)
      @bundle = Bundle.new(fs: fs, command_runner: command_runner)
      @database = Database.new
    end

    def create
      fs.clean
      generate

      fs.within_project do
        remove_unwanted_gems
      end
    end

    def evaluate!(code)
      command_runner = nil

      Dir::Tmpname.create(
        ["", ".rb"],
        fs.find_in_project("tmp"),
      ) do |path, _, _, _|
        tempfile = fs.write_file(path, code)

        command_runner = run_command!(
          "ruby",
          tempfile.to_s,
          err: nil,
          env: { "RUBYOPT" => "" },
        )
      end

      command_runner.output
    end

    def run_command(*args, &block)
      command_runner.run(*args, &block)
    end

    def run_command!(*args, &block)
      command_runner.run!(*args, &block)
    end

    def migration_class_name
      if rails_version > 5
        number = [rails_version.major, rails_version.minor].join(".").to_f
        "ActiveRecord::Migration[#{number}]"
      else
        "ActiveRecord::Migration"
      end
    end

    def rails_version
      @_rails_version ||= bundle.version_of("rails")
    end

    private

    attr_reader :fs, :command_runner, :bundle, :database

    def migrations_directory
      fs.find_in_project("db/migrate")
    end

    def temp_view_path_for(path)
      temp_views_directory.join(path)
    end

    def generate
      rails_new
      fix_available_locales_warning
      remove_bootsnap
      write_database_configuration
      configure_tests_to_run_in_sorted_order

      if bundle.version_of("rails") >= 5
        add_initializer_for_time_zone_aware_types
      end
    end

    def rails_new
      CommandRunner.run!(
        %W(rails new #{fs.project_directory} --skip-bundle --no-rc),
      )
    end

    def fix_available_locales_warning
      # See here for more on this:
      # http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning
      fs.transform_file("config/application.rb") do |lines|
        lines.insert(-3, <<-TEXT)
if I18n.respond_to?(:enforce_available_locales=)
  I18n.enforce_available_locales = false
end
        TEXT
      end
    end

    def remove_bootsnap
      # Rails 5.2 introduced bootsnap, which is helpful when you're developing
      # or deploying an app, but we don't really need it (and it messes with
      # Zeus anyhow)
      fs.comment_lines_matching_in_file(
        "config/boot.rb",
        %r{\Arequire 'bootsnap/setup'},
      )
    end

    def write_database_configuration
      fs.open_file("config/database.yml", "w") do |f|
        YAML.dump(database.config.to_hash, f)
      end
    end

    def configure_tests_to_run_in_sorted_order
      fs.transform_file("config/environments/test.rb") do |lines|
        lines.insert(-2, <<-CONTENT)
  config.active_support.test_order = :sorted
        CONTENT
      end
    end

    def add_initializer_for_time_zone_aware_types
      path = "config/initializers/configure_time_zone_aware_types.rb"
      fs.write_file(path, <<-TEXT)
Rails.application.configure do
  config.active_record.time_zone_aware_types = [:datetime, :time]
end
      TEXT
    end

    def remove_unwanted_gems
      bundle.updating do
        bundle.remove_gem "debugger"
        bundle.remove_gem "byebug"
        bundle.add_gem "pry-byebug"
        bundle.remove_gem "web-console"
      end
    end
  end
end
