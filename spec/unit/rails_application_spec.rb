require "spec_helper"

RSpec.describe Snowglobe::RailsApplication do
  extend Helpers
  include Helpers

  attr_reader :previous_configuration, :app

  before :all do
    if temporary_directory.exist?
      temporary_directory.rmtree
    end

    @previous_configuration = Snowglobe.configuration
    Snowglobe.configuration = Snowglobe::Configuration.new.tap do |config|
      config.temporary_directory = temporary_directory
      config.project_name = project_name
    end

    @app = described_class.new
    app.create
  end

  after :all do
    Snowglobe.configuration = previous_configuration
  end

  describe "#generate" do
    it "generates a Rails application in a temporary directory" do
      expect(temporary_directory.exist?).to be(true)
    end

    it "does not include any Webpacker stuff" do
      expect(app_directory.join("app/javascript").exist?).not_to be(true)
    end

    if rails_version >= "5.2"
      it "removes Bootsnap" do
        expect("Gemfile").to have_commented_out_line_starting_with(
          "gem 'bootsnap'"
        )
        expect("config/boot.rb").to have_commented_out_line_starting_with(
          "require 'bootsnap/setup'"
        )
      end
    end

    if Snowglobe::Database.adapter_name == :postgresql
      it "configures the app to use Postgres" do
        expect("Gemfile").not_to have_commented_out_line_starting_with(
          "gem 'pg'"
        )
        expect(read_yaml("config/database.yml")).to eq({
          "development" => {
            "adapter" => "postgresql",
            "database" => app_name
          },
          "test" => {
            "adapter" => "postgresql",
            "database" => app_name
          },
          "production" => {
            "adapter" => "postgresql",
            "database" => app_name
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
          expect(app.migration_class_name).to eq(
            "ActiveRecord::Migration[#{current_rails_version}]"
          )
        end
      else
        raise "Unhandled Rails version: #{current_rails_version}"
      end
    else
      it "returns the legacy migration class" do
        expect(app.migration_class_name).to eq("ActiveRecord::Migration")
      end
    end
  end

  describe "#rails_version" do
    it "returns the current Rails version, as a GemVersion object" do
      expect(app.rails_version).to eq(rails_version)
    end
  end

  matcher :have_line_starting_with do |partial_line|
    match do |file_path|
      @file_path = file_path
      lines.any? { |line| line.match?(/\A[ ]*#{Regexp.escape(partial_line)}/) }
    end

    failure_message do
      "Expected #{@file_path} to have a line starting with " +
        "#{partial_line.inspect}, but it did not.\n\n" +
        "Content of #{@file_path}:\n\n" +
        Snowglobe::OutputHelpers.bookended(lines.join("\n"))
    end

    failure_message_when_negated do
      "Expected #{@file_path} not to have a commented out line matching " +
        "#{partial_line.inspect}, but it did."
    end

    def lines
      @_lines ||= lines_in(@file_path)
    end
  end

  matcher :have_commented_out_line_starting_with do |partial_line|
    match do |file_path|
      @file_path = file_path
      lines.any? { |line| line.match?(/\A#+[ ]*#{Regexp.escape(partial_line)}/) }
    end

    failure_message do
      "Expected #{@file_path} to have a commented out line starting with " +
        "#{partial_line.inspect}, but it did not.\n\n" +
        "Content of #{@file_path}:\n\n" +
        Snowglobe::OutputHelpers.bookended(lines.join("\n"))
    end

    failure_message_when_negated do
      "Expected #{@file_path} not to have a commented out line matching " +
        "#{partial_line.inspect}, but it did."
    end

    def lines
      @_lines ||= lines_in(@file_path)
    end
  end

  def expect_to_be_commented_out_in(file_path, partial_line)
    expect(lines_in(file_path)).to include(
      a_string_matching(/\A#+#{partial_line}/)
    )
  end

  def expect_not_to_be_commented_out_in(file_path, partial_line)
    expect(lines_in(file_path)).not_to include(
      a_string_matching(/\A#+#{partial_line}/)
    )
  end

  def lines_in(file_path)
    app_directory.join(file_path).readlines.map(&:chomp)
  end

  def read_yaml(file_path)
    YAML.safe_load(app_directory.join(file_path).read)
  end

  def app_directory
    temporary_directory.join(app_name)
  end

  def app_name
    "#{project_name}-test-app"
  end

  def project_name
    "testapp"
  end

  def temporary_directory
    Pathname.new("../..").expand_path(__dir__).join("tmp")
  end
end
