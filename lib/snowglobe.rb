require_relative "snowglobe/configuration"
require_relative "snowglobe/rails_application"
require_relative "snowglobe/version"

module Snowglobe
  class << self
    attr_writer :configuration

    def configure(&block)
      configuration.update!(&block)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
