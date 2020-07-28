module ProjectHelpers
  def lines_in(file_path)
    project_directory.join(file_path).readlines.map(&:chomp)
  end

  def read_yaml(file_path)
    YAML.safe_load(project_directory.join(file_path).read)
  end

  def project_directory
    temporary_directory.join(project_name)
  end

  def project_name
    "example"
  end

  def temporary_directory
    Pathname.new("../..").expand_path(__dir__).join("tmp")
  end

  def project
    @project
  end
end

RSpec.configure do |config|
  config.include ProjectHelpers, project: true

  config.before :all, project: true do
    if temporary_directory.exist?
      temporary_directory.rmtree
    end

    @previous_configuration = Snowglobe.configuration
    Snowglobe.configuration = Snowglobe::Configuration.new.tap do |c|
      c.temporary_directory = temporary_directory
      c.project_name = project_name
    end

    @project = described_class.create
  end

  config.after :all, project: true do
    Snowglobe.configuration = @previous_configuration
  end
end
