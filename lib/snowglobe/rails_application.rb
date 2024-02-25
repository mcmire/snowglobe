require "yaml"

require_relative "project"

module Snowglobe
  class RailsApplication < Project
    def initialize
      super
      @database = Database.new
    end

    def run_migrations!
      command_runner.run_rake_tasks!(["db:drop", "db:create", "db:migrate"])
    end

    def migration_class_name
      if rails_version >= 5
        number = [rails_version.major, rails_version.minor].join(".").to_f
        "ActiveRecord::Migration[#{number}]"
      else
        "ActiveRecord::Migration"
      end
    end

    def rails_version
      @_rails_version ||= bundle.version_of("rails")
    end

    protected

    def generate
      rails_new

      write_database_configuration
      configure_tests_to_run_in_sorted_order

      if rails_version >= 5
        add_initializer_for_time_zone_aware_types
      end

      remove_unwanted_gems
    end

    private

    attr_reader :database

    def migrations_directory
      fs.find_in_project("db/migrate")
    end

    def temp_view_path_for(path)
      temp_views_directory.join(path)
    end

    def rails_new
      CommandRunner.run!(
        "rails",
        "new",
        fs.project_directory,
        "--skip-bundle",
        "--skip-javascript",
        "--skip-bootsnap",
        "--no-rc"
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
      # Rails 5.0 added `time_zone_aware_types`. Make sure the setting is the
      # same for all apps > 5. See: <https://github.com/rails/rails/pull/15726>
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
