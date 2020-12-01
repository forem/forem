require 'rspec/matchers/fail_matchers'

RSpec.describe RSpecHelpers do
  def deprecate!(message)
    RSpec.configuration.reporter.deprecation(:message => message)
  end

  def fail_with(snippet)
    raise_error(RSpec::Mocks::MockExpectationError, snippet)
  end

  def raise_unrelated_expectation!
    raise(RSpec::Expectations::ExpectationNotMetError, 'abracadabra')
  end

  describe '#expect_no_deprecations' do
    shared_examples_for 'expects no deprecations' do
      it 'passes when there were no deprecations' do
        expectation
      end

      it 'fails when there was a deprecation warning' do
        in_sub_process do
          expect {
            expectation
            deprecate!('foo')
          }.to fail_with(/received: 1 time/)
        end
      end

      it 'fails with a MockExpectationError when there was also an ExpectationNotMetError' do
        in_sub_process do
          expect {
            expectation
            deprecate!('bar')
            raise_unrelated_expectation!
          }.to fail_with(/received: 1 time/)
        end
      end
    end

    it_behaves_like 'expects no deprecations' do
      def expectation
        expect_no_deprecations
      end
    end

    # Alias
    it_behaves_like 'expects no deprecations' do
      def expectation
        expect_no_deprecation
      end
    end
  end

  describe '#expect_warn_deprecation' do
    it 'passes when there was a deprecation warning' do
      in_sub_process do
        expect_warn_deprecation(/bar/)
        deprecate!('bar')
      end
    end

    pending 'fails when there were no deprecations' do
      in_sub_process do
        expect {
          expect_warn_deprecation(/bar/)
        }.to raise_error(/received: 0 times/)
      end
    end

    it 'fails with a MockExpectationError when there was also an ExpectationNotMetError' do
      in_sub_process do
        expect {
          expect_warn_deprecation(/bar/)
          deprecate!('bar')
          raise_unrelated_expectation!
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    it 'fails when deprecation message is different' do
      in_sub_process do
        expect {
          expect_warn_deprecation(/bar/)
          deprecate!('foo')
        }.to raise_error(%r{match /bar/})
      end
    end

    it 'fails when deprecation message is different and an ExpectationNotMetError was raised' do
      in_sub_process do
        expect {
          expect_warn_deprecation(/bar/)
          deprecate!('foo')
          raise_unrelated_expectation!
        }.to raise_error(%r{match /bar/})
      end
    end
  end
end
