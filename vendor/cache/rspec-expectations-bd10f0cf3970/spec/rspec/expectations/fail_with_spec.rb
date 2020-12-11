RSpec.describe RSpec::Expectations, "#fail_with" do
  let(:differ) { double("differ") }

  before(:example) do
    allow(RSpec::Matchers.configuration).to receive_messages(:color? => false)
    allow(RSpec::Expectations).to receive(:differ) { differ }
  end

  it "includes a diff if expected and actual are diffable" do
    expect(differ).to receive(:diff).and_return("diff text")

    expect {
      RSpec::Expectations.fail_with "message", "abc", "def"
    }.to fail_with("message\nDiff:diff text")
  end

  it "does not include the diff if expected and actual are not diffable" do
    expect(differ).to receive(:diff).and_return("")

    expect {
      RSpec::Expectations.fail_with "message", "abc", "def"
    }.to fail_with("message")
  end

  it "raises an error if message is not present" do
    expect(differ).not_to receive(:diff)

    expect {
      RSpec::Expectations.fail_with nil
    }.to raise_error(ArgumentError, /Failure message is nil\./)
  end
end

RSpec.describe RSpec::Expectations, "#fail_with with matchers" do
  include RSpec::Support::Spec::DiffHelpers

  before do
    allow(RSpec::Matchers.configuration).to receive_messages(:color? => false)
  end

  it "uses matcher descriptions in place of matchers in diffs" do
    expected = [a_string_matching(/foo/), a_string_matching(/bar/)]
    actual = ["poo", "car"]

    expected_diff = dedent(<<-EOS)
      |
      |@@ #{one_line_header} @@
      |-["poo", "car"]
      |+[(a string matching /foo/), (a string matching /bar/)]
      |
    EOS

    expect {
      RSpec::Expectations.fail_with "message", actual, expected
    }.to fail_with("message\nDiff:#{expected_diff}")
  end
end

RSpec.describe RSpec::Expectations, "#fail_with with --color" do
  include RSpec::Support::Spec::DiffHelpers

  before do
    allow(RSpec::Matchers.configuration).to receive_messages(:color? => true)
  end

  it "tells the differ to use color" do
    expected = "foo bar baz\n"
    actual = "foo bang baz\n"
    expected_diff = "\e[0m\n\e[0m\e[34m@@ #{one_line_header} @@\n\e[0m\e[31m-foo bang baz\n\e[0m\e[32m+foo bar baz\n\e[0m"

    expect {
      RSpec::Expectations.fail_with "message", actual, expected
    }.to fail_with("message\nDiff:#{expected_diff}")
  end
end
