require_relative "database_configuration"

module Snowglobe
  class Database
    def self.adapter_name
      ENV.fetch("DATABASE_ADAPTER", "sqlite3").to_sym
    end

    attr_reader :config

    def initialize
      @config = DatabaseConfiguration.for(
        Snowglobe.configuration.database_name,
        self.class.adapter_name
      )
    end

    def name
      config.database
    end

    def adapter_name
      config.adapter
    end

    def adapter_class
      config.adapter_class
    end
  end
end
