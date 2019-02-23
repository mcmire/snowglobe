require "fileutils"

module Snowglobe
  class Filesystem
    def temporary_directory
      Snowglobe.temporary_directory
    end

    def project_directory
      temporary_directory.join(Snowglobe.project_name)
    end

    def wrap(path)
      if path.is_a?(Pathname)
        path
      else
        find_in_project(path)
      end
    end

    def within_project(&block)
      Dir.chdir(project_directory, &block)
    end

    def clean
      if temporary_directory.exist?
        temporary_directory.rmtree
      end
    end

    def create
      project_directory.mkpath
    end

    def find_in_project(path)
      project_directory.join(path)
    end

    def open(path, *args, &block)
      find_in_project(path).open(*args, &block)
    end

    def read(path)
      find_in_project(path).read
    end

    def write(path, content)
      pathname = wrap(path)
      create_parents_of(pathname)
      pathname.open("w") { |f| f.write(content) }
    end

    def create_parents_of(path)
      wrap(path).dirname.mkpath
    end

    def append_to_file(path, content, _options = {})
      create_parents_of(path)
      File.open(path, "a") { |f| f.puts(content + "\n") }
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
  end
end
