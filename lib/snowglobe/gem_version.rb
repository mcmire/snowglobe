module Snowglobe
  class GemVersion
    def initialize(version)
      @version = Gem::Version.new(version.to_s + "")
    end

    def major
      segments[0]
    end

    def minor
      segments[1]
    end

    def <(other)
      compare?(:<, other)
    end

    def <=(other)
      compare?(:<=, other)
    end

    def ==(other)
      (other.is_a?(self.class) && version == other.__send__(:version)) ||
        compare?(:==, other)
    end

    def >=(other)
      compare?(:>=, other)
    end

    def >(other)
      compare?(:>, other)
    end

    def =~(other)
      Gem::Requirement.new(other).satisfied_by?(version)
    end

    def to_s
      version.to_s
    end

    private

    attr_reader :version

    def segments
      @_segments ||= version.to_s.split(".")
    end

    def compare?(op, other)
      Gem::Requirement.new("#{op} #{other}").satisfied_by?(version)
    end
  end
end
