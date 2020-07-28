require_relative "project"

module Snowglobe
  class MinitestProject < Project
    protected

    def generate
      fs.create_project

      fs.write_file("Gemfile", <<~CONTENT)
        source "https://rubygems.org"

        gem "minitest"
      CONTENT

      fs.write_file("test/test_helper.rb", <<~CONTENT)
        require "minitest/autorun"
      CONTENT
    end
  end
end
