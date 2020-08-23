require "spec_helper"

RSpec.describe Snowglobe::RSpecProject, project: true do
  describe ".create" do
    it "creates a directory for the project" do
      expect(project_directory.exist?).to be(true)
    end

    it "adds a Gemfile with RSpec in it" do
      expect("Gemfile").to have_line_starting_with('gem "rspec"')
    end

    it "sets up the project for testing with RSpec" do
      expect(project_directory.join(".rspec").exist?).to be(true)
      expect(project_directory.join("spec/spec_helper.rb").exist?).to be(true)
    end

    it "creates a project where an RSpec test can be run" do
      project.write_file("spec/foo_spec.rb", <<~TEST)
        require "spec_helper"

        describe 'Some test' do
          it 'works' do
            expect(true).to be(true)
          end
        end
      TEST

      expect(project.run_rspec_test_suite)
        .to have_run_successfully
    end
  end
end
