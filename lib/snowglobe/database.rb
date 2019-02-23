require_relative "database_configuration"

module Snowglobe
  class Database
    include Singleton
    ADAPTER_NAME = ENV.fetch("DATABASE_ADAPTER", "sqlite3").to_sym

    attr_reader :config

    def initialize
      @config = Tests::DatabaseConfiguration.for(
        Snowglobe.database_name,
        ADAPTER_NAME,
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
