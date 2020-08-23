module Matchers
  def have_run_successfully
    HaveRunSuccessfullyMatcher.new
  end

  class HaveRunSuccessfullyMatcher
    def matches?(command)
      @command = command
      command.success?
    end

    def failure_message
      "Expected command to have run successfully, but it did not.\n\n" +
        "Output was:\n\n" +
        Snowglobe::OutputHelpers.bookended(command.output)
    end

    private

    attr_reader :command
  end
end
