RSpec.shared_examples "an RSpec matcher" do |options|
  let(:valid_value)   { options.fetch(:valid_value) }
  let(:invalid_value) { options.fetch(:invalid_value) }

  # Note: do not use `matcher` in 2 expectation expressions in a single
  # example here. In some cases (such as `change { }.to(2)`), it will fail
  # because using it a second time will apply `x += 2` twice, changing
  # the value to 4.

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

  matcher :always_passes do
    supports_block_expectations
    match do |actual|
      actual.call if Proc === actual
      true
    end
  end

  matcher :always_fails do
    supports_block_expectations
    match do |actual|
      actual.call if Proc === actual
      false
    end
  end

  it 'allows additional matchers to be chained off it using `and`' do
    expect(valid_value).to matcher.and always_passes
  end

  it 'can be chained off of an existing matcher using `and`' do
    expect(valid_value).to always_passes.and matcher
  end

  it 'allows additional matchers to be chained off it using `or`' do
    expect(valid_value).to matcher.or always_fails
  end

  it 'can be chained off of an existing matcher using `or`' do
    expect(valid_value).to always_fails.or matcher
  end

  it 'implements the full matcher protocol' do
    expect(matcher).to respond_to(
      :matches?,
      :failure_message,
      :description,
      :supports_block_expectations?,
      :expects_call_stack_jump?
    )

    # We do not require failure_message_when_negated and does_not_match?
    # Because some matchers purposefully do not support negation.
  end

  it 'fails gracefully when given a value if it is a block matcher' do
    if matcher.supports_block_expectations?
      expect {
        expect(3).to matcher
      }.to fail_with(/was not( given)? a block/)

      unless options[:disallows_negation]
        expect {
          expect(3).not_to matcher
        }.to fail_with(/was not( given)? a block/)
      end
    end
  end

  it 'can be used in a composed matcher expression' do
    expect([valid_value, invalid_value]).to include(matcher)

    expect {
      expect([invalid_value]).to include(matcher)
    }.to fail_including("include (#{matcher.description})")
  end

  it 'can match negatively properly' do
    unless options[:disallows_negation]
      expect(invalid_value).not_to matcher

      expect {
        expect(valid_value).not_to matcher
      }.to fail
    end
  end

  it 'uses the `ObjectFormatter` for `failure_message`' do
    allow(RSpec::Support::ObjectFormatter).to receive(:format).and_return("detailed inspect")
    matcher.matches?(invalid_value)
    message = matcher.failure_message

    # Undo our stub so it doesn't affect the `include` matcher below.
    allow(RSpec::Support::ObjectFormatter).to receive(:format).and_call_original
    expect(message).to include("detailed inspect")
  end unless options[:failure_message_uses_no_inspect]
end

