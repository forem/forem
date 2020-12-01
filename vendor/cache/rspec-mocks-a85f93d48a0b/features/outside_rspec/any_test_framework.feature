Feature: Integrate with any test framework

  rspec-mocks is a stand-alone gem that can be integrated with any test framework. The
  example below demonstrates using rspec-mocks with [minitest](http://docs.seattlerb.org/minitest/), but these steps
  would apply when integrating rspec-mocks with any library or framework:

    * Include `RSpec::Mocks::ExampleMethods` in your test context. This provides rspec-mocks' API.
    * Call `RSpec::Mocks.setup` before a test begins.
    * Call `RSpec::Mocks.verify` after a test completes to verify message expectations. Note
      that this step is optional; rspec-core, for example, skips this when an example has already failed.
    * Call `RSpec::Mocks.teardown` after a test completes (and after `verify`) to cleanup. This
      _must_ be called, even if an error has occurred, so it generally goes in an `ensure` clause.

  Note: if you are using minitest, you'll probably want to use the built-in [minitest integration](./integrate-with-minitest).

  Scenario: Use rspec-mocks with Minitest
    Given a file named "test/test_helper.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'rspec/mocks'

      module MinitestRSpecMocksIntegration
        include ::RSpec::Mocks::ExampleMethods

        def before_setup
          ::RSpec::Mocks.setup
          super
        end

        def after_teardown
          super
          ::RSpec::Mocks.verify
        ensure
          ::RSpec::Mocks.teardown
        end
      end

      Minitest::Test.send(:include, MinitestRSpecMocksIntegration)
      """
    And a file named "test/rspec_mocks_test.rb" with:
      """ruby
      require 'test_helper'

      class RSpecMocksTest < Minitest::Test
        def test_passing_positive_expectation
          dbl = double
          expect(dbl).to receive(:message)
          dbl.message
        end

        def test_failing_positive_expectation
          dbl = double
          expect(dbl).to receive(:message)
        end

        def test_passing_negative_expectation
          dbl = double
          expect(dbl).to_not receive(:message)
        end

        def test_failing_negative_expectation
          dbl = double
          expect(dbl).to_not receive(:message)
          dbl.message
        end

        def test_passing_positive_spy_expectation
          bond = spy
          bond.james
          expect(bond).to have_received(:james)
        end

        def test_failing_positive_spy_expectation
          bond = spy
          expect(bond).to have_received(:james)
        end

        def test_passing_negative_spy_expectation
          bond = spy
          expect(bond).not_to have_received(:james)
        end

        def test_failing_negative_spy_expectation
          bond = spy
          bond.james
          expect(bond).not_to have_received(:james)
        end
      end
      """
     When I run `ruby -Itest test/rspec_mocks_test.rb`
     Then it should fail with the following output:
       |   1) Error:                                                                   |
       | RSpecMocksTest#test_failing_negative_expectation:                             |
       | RSpec::Mocks::MockExpectationError: (Double (anonymous)).message(no args)     |
       |     expected: 0 times with any arguments                                      |
       |     received: 1 time                                                          |
       |                                                                               |
       |   2) Error:                                                                   |
       | RSpecMocksTest#test_failing_positive_expectation:                             |
       | RSpec::Mocks::MockExpectationError: (Double (anonymous)).message(*(any args)) |
       |     expected: 1 time with any arguments                                       |
       |     received: 0 times with any arguments                                      |
       |                                                                               |
       |   3) Error:                                                                   |
       | RSpecMocksTest#test_failing_positive_spy_expectation:                         |
       | RSpec::Mocks::MockExpectationError: (Double (anonymous)).james(*(any args))   |
       |     expected: 1 time with any arguments                                       |
       |     received: 0 times with any arguments                                      |
       |                                                                               |
       |   4) Error:                                                                   |
       | RSpecMocksTest#test_failing_negative_spy_expectation:                         |
       | RSpec::Mocks::MockExpectationError: (Double (anonymous)).james(no args)       |
       |     expected: 0 times with any arguments                                      |
       |     received: 1 time                                                          |
       |                                                                               |
       |  8 runs, 0 assertions, 0 failures, 4 errors, 0 skips                          |
