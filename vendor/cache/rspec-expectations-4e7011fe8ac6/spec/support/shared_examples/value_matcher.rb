RSpec.shared_examples "an RSpec value matcher" do |options|
  let(:valid_value)   { options.fetch(:valid_value) }
  let(:invalid_value) { options.fetch(:invalid_value) }

  matcher :always_passes do
    match { |_actual| true }
  end

  matcher :always_fails do
    match { |_actual| false }
  end

  def valid_expectation
    expect(valid_value)
  end

  def invalid_expectation
    expect(invalid_value)
  end

  include_examples "an RSpec matcher", options

  it 'preserves the symmetric property of `==`' do
    expect(matcher).to eq(matcher)
    expect(matcher).not_to eq(valid_value)
    expect(valid_value).not_to eq(matcher)
  end

  it 'matches a valid value when using #=== so it can be composed' do
    expect(matcher).to be === valid_value
  end

  it 'does not match an invalid value when using #=== so it can be composed' do
    expect(matcher).not_to be === invalid_value
  end

  it 'can be used in a composed matcher expression' do
    expect([valid_value, invalid_value]).to include(matcher)

    expect {
      expect([invalid_value]).to include(matcher)
    }.to fail_including("include (#{matcher.description})")
  end

  it 'uses the `ObjectFormatter` for `failure_message`' do
    allow(RSpec::Support::ObjectFormatter).to receive(:format).and_return("detailed inspect")
    matcher.matches?(invalid_value)
    message = matcher.failure_message

    # Undo our stub so it doesn't affect the `include` matcher below.
    allow(RSpec::Support::ObjectFormatter).to receive(:format).and_call_original
    expect(message).to include("detailed inspect")
  end

  it 'fails when given a block' do
    expect {
      expect { 2 + 2 }.to matcher
    }.to fail_with(/must pass an argument rather than a block/)

    unless options[:disallows_negation]
      expect {
        expect { 2 + 2 }.not_to matcher
      }.to fail_with(/must pass an argument rather than a block/)
    end
  end
end
