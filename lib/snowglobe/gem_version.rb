module Snowglobe
  class GemVersion
    def initialize(version)
      @version = Gem::Version.new(version.to_s + "")
    end

    def <(other)
      compare?(:<, other)
    end

    def <=(other)
      compare?(:<=, other)
    end

    def ==(other)
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

    protected

    attr_reader :version

    private

    def compare?(op, other)
      Gem::Requirement.new("#{op} #{other}").satisfied_by?(version)
    end
  end
end
