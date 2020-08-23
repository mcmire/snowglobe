require "spec_helper"

RSpec.describe Snowglobe::MinitestProject, project: true do
  describe ".create" do
    it "creates a directory for the project" do
      expect(project_directory.exist?).to be(true)
    end

    it "adds a Gemfile with Minitest in it" do
      expect("Gemfile").to have_line_starting_with('gem "minitest"')
    end

    it "sets up the project for testing with Minitest" do
      expect(project_directory.join("test/test_helper.rb").exist?).to be(true)
      expect("test/test_helper.rb").to have_line_starting_with(
        'require "minitest/autorun"'
      )
    end

    it "creates a project where a Minitest test can be run" do
      project.write_file("test/example_test.rb", <<~TEST)
        require "test_helper"

        describe 'Example' do
          it 'works' do
            assert true
          end
        end
      TEST

      expect(project.run_n_unit_tests("test/example_test.rb"))
        .to have_run_successfully
    end
  end
end
