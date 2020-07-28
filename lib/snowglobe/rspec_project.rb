require_relative "project"

module Snowglobe
  class RSpecProject < Project
    protected

    def generate
      fs.create_project

      fs.write_file("Gemfile", <<~CONTENT)
        source "https://rubygems.org"

        gem "rspec"
      CONTENT

      run!("rspec --init")
    end
  end
end
