module Helpers
  def rails_version
    Snowglobe::GemVersion.new(Rails.version.to_s)
  end
end
