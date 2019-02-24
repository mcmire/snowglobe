require_relative "snowglobe/configuration"
require_relative "snowglobe/rails_application"
require_relative "snowglobe/version"

module Snowglobe
  def self.configure(&block)
    configuration.update!(&block)
  end

  def self.configuration
    @_configuration ||= Configuration.new
  end
end
