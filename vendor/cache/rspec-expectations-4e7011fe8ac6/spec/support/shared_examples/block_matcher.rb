RSpec.shared_examples "an RSpec block-only matcher" do |*options|
  # Note: Ruby 1.8 expects you to call a block with arguments if it is
  # declared that accept arguments. In this case, some of the specs
  # that include examples from this shared example group do not pass
  # arguments. A workaround is to use splat and pick the first argument
  # if it was passed.
  options = options.first || {}

  # Note: do not use `matcher` in 2 expectation expressions in a single
  # example here. In some cases (such as `change { x += 2 }.to(2)`), it
  # will fail because using it a second time will apply `x += 2` twice,
  # changing the value to 4.

  matcher :always_passes do
    supports_block_expectations
    match do |actual|
      actual.call
      true
    end
  end

  matcher :always_fails do
    supports_block_expectations
    match do |actual|
      actual.call
      false
    end
  end

  let(:valid_expectation) { expect { valid_block } }
  let(:invalid_expectation) { expect { invalid_block } }

  let(:valid_block_lambda) { lambda { valid_block } }
  let(:invalid_block_lambda) { lambda { invalid_block } }

  include_examples "an RSpec matcher", options

  it 'preserves the symmetric property of `==`' do
    expect(matcher).to eq(matcher)
    expect(matcher).not_to eq(valid_block_lambda)
    expect(valid_block_lambda).not_to eq(matcher)
  end

  it 'matches a valid block when using #=== so it can be composed' do
    expect(matcher).to be === valid_block_lambda
  end

  it 'does not match an invalid block when using #=== so it can be composed' do
    expect(matcher).not_to be === invalid_block_lambda
  end

  it 'matches a valid block when using #=== so it can be composed' do
    expect(matcher).to be === valid_block_lambda
  end

  it 'does not match an invalid block when using #=== so it can be composed' do
    expect(matcher).not_to be === invalid_block_lambda
  end

  it 'uses the `ObjectFormatter` for `failure_message`' do
    allow(RSpec::Support::ObjectFormatter).to receive(:format).and_return("detailed inspect")
    expect { invalid_expectation.to matcher }.to raise_error do |error|
      # Undo our stub so it doesn't affect the `include` matcher below.
      allow(RSpec::Support::ObjectFormatter).to receive(:format).and_call_original
      expect(error.message).to include("detailed inspect")
    end
  end unless options[:failure_message_uses_no_inspect]

  it 'fails gracefully when given a value' do
    expect {
      expect(3).to matcher
    }.to fail_with(/was not( given)? a block/)

    unless options[:disallows_negation]
      expect {
        expect(3).not_to matcher
      }.to fail_with(/was not( given)? a block/)
    end
  end

  it 'prints a deprecation warning when given a value' do
    expect_warn_deprecation(/The implicit block expectation syntax is deprecated, you should pass/)
    expect { expect(3).to matcher }.to fail
  end unless options[:skip_deprecation_check] || options[:expects_lambda]

  it 'prints a deprecation warning when given a value and negated' do
    expect_warn_deprecation(/The implicit block expectation syntax is deprecated, you should pass/)
    expect { expect(3).not_to matcher }.to fail
  end unless options[:disallows_negation] || options[:expects_lambda]

  it 'allows lambda expectation target' do
    allow_deprecation
    expect(valid_block_lambda).to matcher
  end
end
