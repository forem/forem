Feature: Receive Counts

  When [expecting a message](../basics/expecting-messages), you can specify how many times you expect the message to be
  received:

    * `expect(...).to receive(...).once`
    * `expect(...).to receive(...).twice`
    * `expect(...).to receive(...).exactly(n).time`
    * `expect(...).to receive(...).exactly(n).times`
    * `expect(...).to receive(...).at_least(:once)`
    * `expect(...).to receive(...).at_least(:twice)`
    * `expect(...).to receive(...).at_least(n).time`
    * `expect(...).to receive(...).at_least(n).times`
    * `expect(...).to receive(...).at_most(:once)`
    * `expect(...).to receive(...).at_most(:twice)`
    * `expect(...).to receive(...).at_most(n).time`
    * `expect(...).to receive(...).at_most(n).times`

  If you don't specify an expected receive count, it defaults to `once`.

  Background:
    Given a file named "lib/account.rb" with:
      """ruby
      class Account
        def initialize(logger)
          @logger = logger
        end

        def open
          @logger.account_opened
        end
      end
      """

  Scenario: Passing examples
    Given a file named "spec/account_spec.rb" with:
      """ruby
      require 'account'

      RSpec.describe Account do
        let(:logger)  { double("Logger") }
        let(:account) { Account.new(logger) }

        example "once" do
          expect(logger).to receive(:account_opened).once
          account.open
        end

        example "twice" do
          expect(logger).to receive(:account_opened).twice
          account.open
          account.open
        end

        example "exactly(n).time" do
          expect(logger).to receive(:account_opened).exactly(1).time
          account.open
        end

        example "exactly(n).times" do
          expect(logger).to receive(:account_opened).exactly(3).times
          account.open
          account.open
          account.open
        end

        example "at_least(:once)" do
          expect(logger).to receive(:account_opened).at_least(:once)
          account.open
          account.open
        end

        example "at_least(:twice)" do
          expect(logger).to receive(:account_opened).at_least(:twice)
          account.open
          account.open
          account.open
        end

        example "at_least(n).time" do
          expect(logger).to receive(:account_opened).at_least(1).time
          account.open
        end

        example "at_least(n).times" do
          expect(logger).to receive(:account_opened).at_least(3).times
          account.open
          account.open
          account.open
          account.open
        end

        example "at_most(:once)" do
          expect(logger).to receive(:account_opened).at_most(:once)
        end

        example "at_most(:twice)" do
          expect(logger).to receive(:account_opened).at_most(:twice)
          account.open
        end

        example "at_most(n).time" do
          expect(logger).to receive(:account_opened).at_most(1).time
          account.open
        end

        example "at_most(n).times" do
          expect(logger).to receive(:account_opened).at_most(3).times
          account.open
          account.open
        end
      end
      """
    When I run `rspec spec/account_spec.rb`
    Then the examples should all pass

  Scenario: Failing examples
    Given a file named "spec/account_spec.rb" with:
      """ruby
      require 'account'

      RSpec.describe Account do
        let(:logger)  { double("Logger") }
        let(:account) { Account.new(logger) }

        example "once" do
          expect(logger).to receive(:account_opened).once
          account.open
          account.open
        end

        example "twice" do
          expect(logger).to receive(:account_opened).twice
          account.open
        end

        example "exactly(n).times" do
          expect(logger).to receive(:account_opened).exactly(3).times
          account.open
          account.open
        end

        example "at_least(:once)" do
          expect(logger).to receive(:account_opened).at_least(:once)
        end

        example "at_least(:twice)" do
          expect(logger).to receive(:account_opened).at_least(:twice)
          account.open
        end

        example "at_least(n).times" do
          expect(logger).to receive(:account_opened).at_least(3).times
          account.open
          account.open
        end

        example "at_most(:once)" do
          expect(logger).to receive(:account_opened).at_most(:once)
          account.open
          account.open
        end

        example "at_most(:twice)" do
          expect(logger).to receive(:account_opened).at_most(:twice)
          account.open
          account.open
          account.open
        end

        example "at_most(n).times" do
          expect(logger).to receive(:account_opened).at_most(3).times
          account.open
          account.open
          account.open
          account.open
        end
      end
      """
    When I run `rspec spec/account_spec.rb --order defined`
    Then the examples should all fail, producing the following output:
      | expected: 1 time with any arguments           |
      | received: 2 times                             |
      |                                               |
      | expected: 2 times with any arguments          |
      | received: 1 time with any arguments           |
      |                                               |
      | expected: 3 times with any arguments          |
      | received: 2 times with any arguments          |
      |                                               |
      | expected: at least 1 time with any arguments  |
      | received: 0 times with any arguments          |
      |                                               |
      | expected: at least 2 times with any arguments |
      | received: 1 time with any arguments           |
      |                                               |
      | expected: at least 3 times with any arguments |
      | received: 2 times with any arguments          |
      |                                               |
      | expected: at most 1 time with any arguments   |
      | received: 2 times                             |
      |                                               |
      | expected: at most 2 times with any arguments  |
      | received: 3 times                             |
      |                                               |
      | expected: at most 3 times with any arguments  |
      | received: 4 times                             |
