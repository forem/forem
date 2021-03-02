RSpec.shared_examples "an RSpec matcher" do |options|
  # Note: do not use `matcher` in 2 expectation expressions in a single
  # example here. In some cases (such as `change { }.to(2)`), it will fail
  # because using it a second time will apply `x += 2` twice, changing
  # the value to 4.

  it 'allows additional matchers to be chained off it using `and`' do
    valid_expectation.to matcher.and always_passes
  end

  it 'can be chained off of an existing matcher using `and`' do
    valid_expectation.to always_passes.and matcher
  end

  it 'allows additional matchers to be chained off it using `or`' do
    valid_expectation.to matcher.or always_fails
  end

  it 'can be chained off of an existing matcher using `or`' do
    valid_expectation.to always_fails.or matcher
  end

  it 'implements the full matcher protocol' do
    expect(matcher).to respond_to(
      :matches?,
      :failure_message,
      :description,
      :supports_block_expectations?,
      :supports_value_expectations?,
      :expects_call_stack_jump?
    )

    # We do not require failure_message_when_negated and does_not_match?
    # Because some matchers purposefully do not support negation.
  end

  it 'can match negatively properly' do
    invalid_expectation.not_to matcher

    expect {
      valid_expectation.not_to matcher
    }.to fail
  end unless options[:disallows_negation]
end
