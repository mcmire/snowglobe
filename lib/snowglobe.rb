require "snowglobe/version"

module Snowglobe
  def self.configure(&block)
    configuration.update!(&block)
  end

  def self.configuration
    @_configuration ||= Configuration.new
  end
end
