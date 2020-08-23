require "fileutils"

module Snowglobe
  class Filesystem
    def clean
      if root_directory.exist?
        root_directory.rmtree
      end
    end

    def project_directory
      root_directory.join(Snowglobe.configuration.project_name)
    end

    def create_project
      project_directory.mkpath
    end

    def within_project(&block)
      Dir.chdir(project_directory, &block)
    end

    def find_in_project(path)
      project_directory.join(path)
    end

    def open_file(path, *args, &block)
      wrap_file(path).open(*args, &block)
    end

    def comment_lines_matching_in_file(path, pattern)
      transform_file(path) do |lines|
        lines.map do |line|
          if line && line =~ pattern
            "###{line}"
          else
            line
          end
        end
      end
    end

    def transform_file(path)
      content = read_file(path)
      lines = content.split(/\n/)
      transformed_lines = yield lines
      write_file(path, transformed_lines.join("\n") + "\n")
    end

    def read_file(path)
      wrap_file(path).read
    end

    def write_file(path, content)
      pathname = wrap_file(path)
      create_parents_of(pathname)
      pathname.open("w") { |f| f.write(content) }
      pathname
    end

    def append_to_file(path, content, _options = {})
      pathname = wrap_file(path)
      create_parents_of(pathname)
      pathname.open("a") { |f| f.puts(content + "\n") }
    end

    def remove_from_file(path, pattern)
      unless pattern.is_a?(Regexp)
        pattern = Regexp.new("^" + Regexp.escape(pattern) + "$")
      end

      transform(path) do |lines|
        lines.reject { |line| line =~ pattern }
      end
    end

    private

    def root_directory
      Snowglobe.configuration.temporary_directory.join("snowglobe")
    end

    def wrap_file(path)
      if path.is_a?(Pathname)
        path
      else
        find_in_project(path)
      end
    end

    def create_parents_of(pathname)
      pathname.dirname.mkpath
    end
  end
end
