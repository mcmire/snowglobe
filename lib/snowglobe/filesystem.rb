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

    def open(path, *args, &block)
      wrap(path).open(*args, &block)
    end

    def read(path)
      wrap(path).read
    end

    def write(path, content)
      pathname = wrap(path)
      create_parents_of(pathname)
      pathname.open("w") { |f| f.write(content) }
      pathname
    end

    def append_to_file(path, content, _options = {})
      pathname = wrap(path)
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

    def comment_lines_matching(path, pattern)
      transform(path) do |lines|
        lines.map do |line|
          if line&.match?(pattern)
            "###{line}"
          else
            line
          end
        end
      end
    end

    def transform(path)
      content = read(path)
      lines = content.split(/\n/)
      transformed_lines = yield lines
      write(path, transformed_lines.join("\n") + "\n")
    end

    private

    def root_directory
      Snowglobe.configuration.temporary_directory
    end

    def wrap(path)
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
