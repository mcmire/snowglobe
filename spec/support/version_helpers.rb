module VersionHelpers
  def rails_version
    Snowglobe::GemVersion.new(Rails.version.to_s)
  end
end

RSpec.configure do |config|
  config.include VersionHelpers
  config.extend VersionHelpers
end
