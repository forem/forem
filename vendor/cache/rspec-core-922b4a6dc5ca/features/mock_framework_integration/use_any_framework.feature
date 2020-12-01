Feature: mock with an alternative framework

  In addition to rspec, mocha, flexmock, and RR, you can choose an alternate
  framework as the mocking framework. You (or the framework authors) just needs
  to provide an adapter that hooks RSpec's events into those of the framework.

  A mock framework adapter must expose three methods:

  * `setup_mocks_for_rspec`
    * called before each example is run
  * `verify_mocks_for_rspec`
    * called after each example is run
    * this is where message expectation failures should result in an error with
      the appropriate failure message
  * `teardown_mocks_for_rspec`
    * called after `verify_mocks_for_rspec`
    * use this to clean up resources, restore objects to earlier state, etc
    * guaranteed to run even if there are failures

  Scenario: Mock with alternate framework
    Given a file named "expector.rb" with:
      """ruby
      class Expector
        class << self
          def expectors
            @expectors ||= []
          end

          def clear_expectors
            expectors.clear
          end

          def verify_expectors
            expectors.each {|d| d.verify}
          end
        end

        def initialize
          self.class.expectors << self
        end

        def expectations
          @expectations ||= []
        end

        def expect(message)
          expectations << message.to_s
        end

        def verify
          unless expectations.empty?
            raise expectations.map {|e|
              "expected #{e}, but it was never received"
            }.join("\n")
          end
        end

      private

        def method_missing(name, *args, &block)
          expectations.delete(name.to_s)
        end

      public

        module RSpecAdapter
          def setup_mocks_for_rspec
            # no setup necessary
          end

          def verify_mocks_for_rspec
            Expector.verify_expectors
          end

          def teardown_mocks_for_rspec
            Expector.clear_expectors
          end
        end
      end
      """

    Given a file named "example_spec.rb" with:
      """ruby
      require File.expand_path("../expector", __FILE__)

      RSpec.configure do |config|
        config.mock_with Expector::RSpecAdapter
      end

      RSpec.describe Expector do
        it "passes when message is received" do
          expector = Expector.new
          expector.expect(:foo)
          expector.foo
        end

        it "fails when message is received" do
          expector = Expector.new
          expector.expect(:foo)
        end
      end
      """
    When I run `rspec example_spec.rb --format doc`
    Then the exit status should be 1
    And the output should contain "2 examples, 1 failure"
    And the output should contain "fails when message is received (FAILED - 1)"
