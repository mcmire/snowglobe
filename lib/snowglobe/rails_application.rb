require "forwardable"
require "yaml"

require_relative "bundle"
require_relative "command_runner"
require_relative "database"
require_relative "filesystem"

module Snowglobe
  class RailsApplication
    extend Forwardable

    def_delegators :bundle, :add_gem

    def initialize
      @fs = Filesystem.new
      @command_runner_proxy = CommandRunnerProxy.new(fs)
      @bundle = Bundle.new(fs: fs, command_runner: command_runner_proxy)
      @database = Database.new
    end

    def create
      fs.clean
      generate

      fs.within_project do
        # install_gems
        remove_unwanted_gems
      end
    end

    # def load
      # load_environment
      # run_migrations
    # end

    def execute!(code)
      command_runner = nil

      Dir::Tmpname.create(
        ["", ".rb"],
        fs.find_in_project("tmp"),
      ) do |path, _, _, _|
        tempfile = fs.write(path, code)

        command_runner = run_command!(
          "ruby",
          tempfile.to_s,
          err: nil,
          env: { "RUBYOPT" => "" },
        )
      end

      command_runner.output
    end

    def run_command!(*args, &block)
      command_runner_proxy.run!(*args, &block)
    end

    def write_file(*args)
      fs.write(*args)
    end

    # def gemfile_path
      # fs.find("Gemfile")
    # end

    # def temp_views_directory
      # fs.find_in_project("tmp/views")
    # end

    # def create_temp_view(path, contents)
      # full_path = temp_view_path_for(path)
      # full_path.dirname.mkpath
      # full_path.open("w") { |f| f.write(contents) }
    # end

    # def delete_temp_views
      # if temp_views_directory.exist?
        # temp_views_directory.rmtree
      # end
    # end

    # def draw_routes(&block)
      # Rails.application.routes.draw(&block)
      # Rails.application.routes
    # end

    private

    attr_reader :fs, :command_runner_proxy, :bundle, :database

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

      if bundle.version_of("rails") >= 5
        add_initializer_for_time_zone_aware_types
      end
    end

    def rails_new
      CommandRunner.run!(
        %W(rails new #{fs.project_directory} --skip-bundle --no-rc)
      )
    end

    def fix_available_locales_warning
      # See here for more on this:
      # http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning
      fs.transform("config/application.rb") do |lines|
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
      fs.comment_lines_matching(
        "config/boot.rb",
        %r{\Arequire 'bootsnap/setup'},
      )
    end

    def write_database_configuration
      YAML.dump(database.config.to_hash, fs.open("config/database.yml", "w"))
    end

    def add_initializer_for_time_zone_aware_types
      path = "config/initializers/configure_time_zone_aware_types.rb"
      fs.write(path, <<-TEXT)
Rails.application.configure do
  config.active_record.time_zone_aware_types = [:datetime, :time]
end
      TEXT
    end

    # def load_environment
      # require environment_file_path
    # end

    # def environment_file_path
      # fs.find_in_project("config/environment")
    # end

    # def run_migrations
      # fs.within_project do
        # run_command! "bundle exec rake db:drop db:create db:migrate"
      # end
    # end

    # def install_gems
      # bundle.install_gems
    # end

    def remove_unwanted_gems
      bundle.updating do
        bundle.remove_gem "debugger"
        bundle.remove_gem "byebug"
        bundle.add_gem "pry-byebug"
        bundle.remove_gem "web-console"
      end
    end

    class CommandRunnerProxy
      def initialize(fs)
        @fs = fs
      end

      def run!(*args, **options, &block)
        CommandRunner.run!(
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
end
