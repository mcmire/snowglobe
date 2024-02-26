require "spec_helper"

RSpec.describe Snowglobe::RailsApplication, project: true do
  describe ".create" do
    it "creates a directory for the application" do
      expect(project_directory.exist?).to be(true)
    end

    it "does not include any Webpacker stuff" do
      expect(project_directory.join("app/javascript").exist?).not_to be(true)
    end

    if Snowglobe::Database.adapter_name == :postgresql
      it "configures the app to use Postgres" do
        expect("Gemfile").not_to have_commented_out_line_starting_with(
          "gem 'pg'"
        )
        expect(read_yaml("config/database.yml")).to eq({
          "development" => {
            "adapter" => "postgresql",
            "database" => project_name
          },
          "test" => {
            "adapter" => "postgresql",
            "database" => project_name
          },
          "production" => {
            "adapter" => "postgresql",
            "database" => project_name
          }
        })
      end
    else
      it "configures the app to use SQLite" do
        expect("Gemfile").not_to have_commented_out_line_starting_with(
          "gem 'sqlite3'"
        )
        expect(read_yaml("config/database.yml")).to eq({
          "development" => {
            "adapter" => "sqlite3",
            "database" => "db/db.sqlite3"
          },
          "test" => {
            "adapter" => "sqlite3",
            "database" => "db/db.sqlite3"
          },
          "production" => {
            "adapter" => "sqlite3",
            "database" => "db/db.sqlite3"
          }
        })
      end
    end

    it "configures tests to run in a sorted order" do
      expect("config/environments/test.rb").to have_line_starting_with(
        "config.active_support.test_order = :sorted"
      )
    end

    if rails_version >= 5
      it "configures ActiveRecord with a consistent set of time-zone-aware column types" do
        expect("config/initializers/configure_time_zone_aware_types.rb")
          .to have_line_starting_with(
            "config.active_record.time_zone_aware_types = [:datetime, :time]"
          )
      end
    end

    it "replaces byebug with pry-byebug" do
      expect("Gemfile").to have_commented_out_line_starting_with("gem 'byebug'")
      expect("Gemfile").to have_line_starting_with("gem 'pry-byebug'")
    end

    it "removes web-console" do
      expect("Gemfile").to have_commented_out_line_starting_with(
        "gem 'web-console'"
      )
    end
  end

  describe "#migration_class_name" do
    if rails_version >= 5
      current_rails_version = [rails_version.major, rails_version.minor]
        .join(".")

      case current_rails_version
      when "6.0", "5.2", "5.1", "5.0"
        it "returns ActiveRecord::Migration[#{current_rails_version}]" do
          expect(project.migration_class_name).to eq(
            "ActiveRecord::Migration[#{current_rails_version}]"
          )
        end
      else
        raise "Unhandled Rails version: #{current_rails_version}"
      end
    else
      it "returns the legacy migration class" do
        expect(project.migration_class_name).to eq("ActiveRecord::Migration")
      end
    end
  end

  describe "#rails_version" do
    it "returns the current Rails version, as a GemVersion object" do
      expect(project.rails_version).to eq(rails_version)
    end
  end
end
