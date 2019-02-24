module Snowglobe
  module TestHelpers
    def rails_app
      @_rails_app ||= RailsApplication.new
    end

    def fs
      rails_app.fs
    end

    def bundle
      rails_app.bundle
    end

    def database
      rails_app.database
    end
  end
end
