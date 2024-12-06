require 'spec_helper'

describe RSpec::Retry do
  def count
    @count ||= 0
    @count
  end

  def count_up
    @count ||= 0
    @count += 1
  end

  def set_expectations(expectations)
    @expectations = expectations
  end

  def shift_expectation
    @expectations.shift
  end

  class RetryError < StandardError; end
  class RetryChildError < RetryError; end
  class HardFailError < StandardError; end
  class HardFailChildError < HardFailError; end
  class OtherError < StandardError; end
  class SharedError < StandardError; end
  before(:all) do
    ENV.delete('RSPEC_RETRY_RETRY_COUNT')
  end

  context 'no retry option' do
    it 'should work' do
      expect(true).to be(true)
    end
  end

  context 'with retry option' do
    before(:each) { count_up }

    context do
      before(:all) { set_expectations([false, false, true]) }

      it 'should run example until :retry times', :retry => 3 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(3)
      end
    end

    context do
      before(:all) { set_expectations([false, true, false]) }

      it 'should stop retrying if  example is succeeded', :retry => 3 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(2)
      end
    end

    context 'with lambda condition' do
      before(:all) { set_expectations([false, true]) }

      it "should get retry count from condition call", retry_me_once: true do
        expect(true).to be(shift_expectation)
        expect(count).to eq(2)
      end
    end

    context 'with :retry => 0' do
      after(:all) { @@this_ran_once = nil }
      it 'should still run once', retry: 0 do
        @@this_ran_once = true
      end

      it 'should run have run once' do
        expect(@@this_ran_once).to be true
      end
    end

    context 'with the environment variable RSPEC_RETRY_RETRY_COUNT' do
      before(:all) do
        set_expectations([false, false, true])
        ENV['RSPEC_RETRY_RETRY_COUNT'] = '3'
      end

      after(:all) do
        ENV.delete('RSPEC_RETRY_RETRY_COUNT')
      end

      it 'should override the retry count set in an example', :retry => 2 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(3)
      end
    end

    context "with exponential backoff enabled", :retry => 3, :retry_wait => 0.001, :exponential_backoff => true do
      context do
        before(:all) do
          set_expectations([false, false, true])
          @start_time = Time.now
        end

        it 'should run example until :retry times', :retry => 3 do
          expect(true).to be(shift_expectation)
          expect(count).to eq(3)
          expect(Time.now - @start_time).to be >= (0.001)
        end
      end
    end

    describe "with a list of exceptions to immediately fail on", :retry => 2, :exceptions_to_hard_fail => [HardFailError] do
      context "the example throws an exception contained in the hard fail list" do
        it "does not retry" do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailError unless count > 1
        end
      end

      context "the example throws a child of an exception contained in the hard fail list" do
        it "does not retry" do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailChildError unless count > 1
        end
      end

      context "the throws an exception not contained in the hard fail list" do
        it "retries the maximum number of times" do
          raise OtherError unless count > 1
          expect(count).to eq(2)
        end
      end
    end

    describe "with a list of exceptions to retry on", :retry => 2, :exceptions_to_retry => [RetryError] do
      context do
        let(:rspec_version) { RSpec::Core::Version::STRING }

        let(:example_code) do
          %{
            $count ||= 0
            $count += 1

            raise NameError unless $count > 2
          }
        end

        let!(:example_group) do
          $count, $example_code = 0, example_code

          RSpec.describe("example group", exceptions_to_retry: [NameError], retry: 3).tap do |this|
            this.run # initialize for rspec 3.3+ with no examples
          end
        end

        let(:retry_attempts) do
          example_group.examples.first.metadata[:retry_attempts]
        end

        it 'should retry and match attempts metadata' do
          example_group.example { instance_eval($example_code) }
          example_group.run

          expect(retry_attempts).to eq(2)
        end

        let(:retry_exceptions) do
          example_group.examples.first.metadata[:retry_exceptions]
        end

        it 'should add exceptions into retry_exceptions metadata array' do
          example_group.example { instance_eval($example_code) }
          example_group.run

          expect(retry_exceptions.count).to eq(2)
          expect(retry_exceptions[0].class).to eq NameError
          expect(retry_exceptions[1].class).to eq NameError
        end
      end

      context "the example throws an exception contained in the retry list" do
        it "retries the maximum number of times" do
          raise RetryError unless count > 1
          expect(count).to eq(2)
        end
      end

      context "the example throws a child of an exception contained in the retry list" do
        it "retries the maximum number of times" do
          raise RetryChildError unless count > 1
          expect(count).to eq(2)
        end
      end

      context "the example fails (with an exception not in the retry list)" do
        it "only runs once" do
          set_expectations([false])
          expect(count).to eq(1)
        end
      end

      context 'the example retries exceptions which match with case equality' do
        class CaseEqualityError < StandardError
          def self.===(other)
            # An example of dynamic matching
            other.message == 'Rescue me!'
          end
        end

        it 'retries the maximum number of times', exceptions_to_retry: [CaseEqualityError] do
          raise StandardError, 'Rescue me!' unless count > 1
          expect(count).to eq(2)
        end
      end
    end

    describe "with both hard fail and retry list of exceptions", :retry => 2, :exceptions_to_retry => [SharedError, RetryError], :exceptions_to_hard_fail => [SharedError, HardFailError] do
      context "the exception thrown exists in both lists" do
        it "does not retry because the hard fail list takes precedence" do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise SharedError unless count > 1
        end
      end

      context "the example throws an exception contained in the hard fail list" do
        it "does not retry because the hard fail list takes precedence" do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailError unless count > 1
        end
      end

      context "the example throws an exception contained in the retry list" do
        it "retries the maximum number of times because the hard fail list doesn't affect this exception" do
          raise RetryError unless count > 1
          expect(count).to eq(2)
        end
      end

      context "the example throws an exception contained in neither list" do
        it "does not retry because the the exception is not in the retry list" do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise OtherError unless count > 1
        end
      end
    end
  end

  describe 'clearing lets' do
    before(:all) do
      @control = true
    end

    let(:let_based_on_control) { @control }

    after do
      @control = false
    end

    it 'should clear the let when the test fails so it can be reset', :retry => 2 do
      expect(let_based_on_control).to be(false)
    end

    it 'should not clear the let when the test fails', :retry => 2, :clear_lets_on_failure => false do
      expect(let_based_on_control).to be(!@control)
    end
  end

  describe 'running example.run_with_retry in an around filter', retry: 2 do
    before(:each) { count_up }
    before(:all) do
      set_expectations([false, false, true])
    end

    it 'allows retry options to be overridden', :overridden do
      expect(RSpec.current_example.metadata[:retry]).to eq(3)
    end

    it 'uses the overridden options', :overridden do
      expect(true).to be(shift_expectation)
      expect(count).to eq(3)
    end
  end

  describe 'calling retry_callback between retries', retry: 2 do
    before(:all) do
      RSpec.configuration.retry_callback = proc do |example|
        @retry_callback_called = true
        @example = example
      end
    end

    after(:all) do
      RSpec.configuration.retry_callback = nil
    end

    context 'if failure' do
      before(:all) do
        @retry_callback_called = false
        @example = nil
        @retry_attempts = 0
      end

      it 'should call retry callback', with_some: 'metadata' do |example|
        if @retry_attempts == 0
          @retry_attempts += 1
          expect(@retry_callback_called).to be(false)
          expect(@example).to eq(nil)
          raise "let's retry once!"
        elsif @retry_attempts > 0
          expect(@retry_callback_called).to be(true)
          expect(@example).to eq(example)
          expect(@example.metadata[:with_some]).to eq('metadata')
        end
      end
    end

    context 'does not call retry_callback if no errors' do
      before(:all) do
        @retry_callback_called = false
        @example = nil
      end

      after do
        expect(@retry_callback_called).to be(false)
        expect(@example).to be_nil
      end

      it { true }
    end
  end

  describe 'Example::Procsy#attempts' do
    let!(:example_group) do
      RSpec.describe do
        before :all do
          @@results = {}
        end

        around do |example|
          example.run_with_retry
          @@results[example.description] = [example.exception.nil?, example.attempts]
        end

        specify 'without retry option' do
          expect(true).to be(true)
        end

        specify 'with retry option', retry: 3 do
          expect(true).to be(false)
        end
      end
    end

    it 'should be exposed' do
      example_group.run
      expect(example_group.class_variable_get(:@@results)).to eq({
        'without retry option' => [true, 1],
        'with retry option' => [false, 3]
      })
    end
  end

  describe 'output in verbose mode' do

    line_1 = __LINE__ + 8
    line_2 = __LINE__ + 11
    let(:group) do
      RSpec.describe 'ExampleGroup', retry: 2 do
        after do
          fail 'broken after hook'
        end

        it 'passes' do
          true
        end

        it 'fails' do
          fail 'broken spec'
        end
      end
    end

    it 'outputs failures correctly' do
      RSpec.configuration.output_stream = output = StringIO.new
      RSpec.configuration.verbose_retry = true
      RSpec.configuration.display_try_failure_messages = true
      expect {
        group.run RSpec.configuration.reporter
      }.to change { output.string }.to a_string_including <<-STRING.gsub(/^\s+\| ?/, '')
        | 1st Try error in ./spec/lib/rspec/retry_spec.rb:#{line_1}:
        | broken after hook
        |
        | RSpec::Retry: 2nd try ./spec/lib/rspec/retry_spec.rb:#{line_1}
        | F
        | 1st Try error in ./spec/lib/rspec/retry_spec.rb:#{line_2}:
        | broken spec
        | broken after hook
        |
        | RSpec::Retry: 2nd try ./spec/lib/rspec/retry_spec.rb:#{line_2}
      STRING
    end
  end
end
