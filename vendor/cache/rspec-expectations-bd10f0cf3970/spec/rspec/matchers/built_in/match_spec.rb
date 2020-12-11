RSpec.describe "expect(...).to match(expected)" do
  include RSpec::Support::Spec::DiffHelpers

  it_behaves_like "an RSpec matcher", :valid_value => 'ab', :invalid_value => 'bc' do
    let(:matcher) { match(/a/) }
  end

  it "passes when target (String) matches expected (Regexp)" do
    expect("string").to match(/tri/)
  end

  it "passes when target (Regexp) matches expected (String)" do
    expect(/tri/).to match("string")
  end

  it "passes when target (Regexp) matches expected (Regexp)" do
    expect(/tri/).to match(/tri/)
  end

  it "passes when target (String) matches expected (a matcher)" do
    expect("string").to match(a_string_including("str"))
  end

  it "passes when target (Regexp) matches expected (a matcher)" do
    expect(/foo/).to match(be_a Regexp)
  end

  it "passes when target (String) matches expected (String)" do
    expect("string").to match("tri")
  end

  it "fails when target (String) does not match expected (Regexp)" do
    expect {
      expect("string").to match(/rings/)
    }.to fail_with a_string_starting_with 'expected "string" to match /rings/'
  end

  it "fails when target (Regexp) does not match expected (String)" do
    expect {
      expect(/rings/).to match("string")
    }.to fail_with a_string_starting_with 'expected /rings/ to match "string"'
  end

  it "fails when target (String) does not match expected (a matcher)" do
    expect {
      expect("string").to match(a_string_including("foo"))
    }.to fail_with(a_string_starting_with 'expected "string" to match (a string including "foo")')
  end

  it "fails when target (Regexp) does not match expected (a matcher)" do
    expect {
      expect(/foo/).to match(be_a_kind_of String)
    }.to fail_with(a_string_starting_with 'expected /foo/ to match (be a kind of String)')
  end

  it "fails when target (String) does not match expected (String)" do
    expect {
      expect("string").to match("rings")
    }.to fail
  end

  it "provides message, expected and actual on failure" do
    matcher = match(/rings/)
    matcher.matches?("string")
    expect(matcher.failure_message).to eq "expected \"string\" to match /rings/"
  end

  it "provides a diff on failure" do
    allow(RSpec::Matchers.configuration).to receive(:color?).and_return(false)

    failure_message_that_includes_diff = %r|
\s*Diff:
\s*@@ #{Regexp.escape one_line_header} @@
\s*-/bar/
\s*\+"foo"|

    expect { expect("foo").to match(/bar/) }.to fail_with(failure_message_that_includes_diff)
  end

  context "when passed a data structure with matchers" do
    it 'passes when the matchers match' do
      expect(["food", 1.1]).to match([a_string_matching(/foo/), a_value_within(0.2).of(1)])
    end

    it 'fails when the matchers do not match' do
      expect {
        expect(["fod", 1.1]).to match([a_string_matching(/foo/), a_value_within(0.2).of(1)])
      }.to fail_with('expected ["fod", 1.1] to match [(a string matching /foo/), (a value within 0.2 of 1)]')
    end

    it 'provides a description' do
      description = match([a_string_matching(/foo/), a_value_within(0.2).of(1)]).description
      expect(description).to eq("match [(a string matching /foo/), (a value within 0.2 of 1)]")
    end
  end
end

RSpec.describe "expect(...).not_to match(expected)" do
  it "passes when target (String) matches does not match (Regexp)" do
    expect("string").not_to match(/rings/)
  end

  it "passes when target (String) matches does not match (String)" do
    expect("string").not_to match("rings")
  end

  it "fails when target (String) matches expected (Regexp)" do
    expect {
      expect("string").not_to match(/tri/)
    }.to fail_with a_string_starting_with 'expected "string" not to match /tri/'
  end

  it "fails when target (String) matches expected (String)" do
    expect {
      expect("string").not_to match("tri")
    }.to fail_with a_string_starting_with 'expected "string" not to match "tri"'
  end

  it "provides message, expected and actual on failure" do
    matcher = match(/tri/)
    matcher.matches?("string")
    expect(matcher.failure_message_when_negated).to eq "expected \"string\" not to match /tri/"
  end

  context "when passed a data structure with matchers" do
    it 'passes when the matchers match' do
      expect(["food", 1.1]).not_to match([a_string_matching(/fod/), a_value_within(0.2).of(1)])
    end

    it 'fails when the matchers do not match' do
      expect {
        expect(["fod", 1.1]).not_to match([a_string_matching(/fod/), a_value_within(0.2).of(1)])
      }.to fail_with('expected ["fod", 1.1] not to match [(a string matching /fod/), (a value within 0.2 of 1)]')
    end
  end
end
