require 'rspec/support/spec/library_wide_checks'

RSpec.describe "RSpec::Rails" do
  include RSpec::Support::WhitespaceChecks

  # Pasted from rspec-support lib/rspec/support/spec/library_wide_checks.rb:134
  # Easier to do that here than to extract it out
  RSpec::Matchers.define :be_well_formed do
    match do |actual|
      actual.empty?
    end

    failure_message do |actual|
      actual.join("\n")
    end
  end

  it "has no malformed whitespace", :slow do
    error_messages = []
    `git ls-files -z`.split("\x0").each do |filename|
      error_messages << check_for_tab_characters(filename)
      error_messages << check_for_extra_spaces(filename)
    end
    expect(error_messages.compact).to be_well_formed
  end
end
