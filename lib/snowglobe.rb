require_relative "snowglobe/configuration"
require_relative "snowglobe/minitest_project"
require_relative "snowglobe/rails_application"
require_relative "snowglobe/rspec_project"
require_relative "snowglobe/version"

module Snowglobe
  class << self
    attr_writer :configuration

    def configure(&block)
      configuration.update!(&block)
    end

    def configuration
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @configuration ||= Configuration.new
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
