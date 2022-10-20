require "tmpdir"

module Snowglobe
  class Configuration
    attr_writer :project_name, :database_name
    attr_reader :temporary_directory

    def initialize
      @project_name = nil
      @database_name = nil
      self.temporary_directory = Dir.tmpdir
    end

    def update!
      yield self
    end

    def project_name
      if @project_name
        @project_name
      else
        raise NotConfiguredError.new(<<~EXAMPLE)
          Snowglobe.configure do |config|
            config.project_name = "your_project_name"
          end
        EXAMPLE
      end
    end

    def database_name
      @database_name || project_name
    end

    def temporary_directory=(path)
      @temporary_directory = Pathname.new(path)
    end

    class NotConfiguredError < StandardError
      def initialize(example)
        super(<<~MESSAGE)
          You need to configure Snowglobe before you can use it! For example:

          #{example}
        MESSAGE
      end
    end
  end
end
