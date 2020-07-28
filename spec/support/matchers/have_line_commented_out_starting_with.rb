RSpec::Matchers.define :have_commented_out_line_starting_with do |partial_line|
  match do |file_path|
    @file_path = file_path
    lines.any? { |line| line.match?(/\A#+[ ]*#{Regexp.escape(partial_line)}/) }
  end

  failure_message do
    "Expected #{@file_path} to have a commented out line starting with " +
      "#{partial_line.inspect}, but it did not.\n\n" +
      "Content of #{@file_path}:\n\n" +
      Snowglobe::OutputHelpers.bookended(lines.join("\n"))
  end

  failure_message_when_negated do
    "Expected #{@file_path} not to have a commented out line matching " +
      "#{partial_line.inspect}, but it did."
  end

  def lines
    @_lines ||= lines_in(@file_path)
  end
end
