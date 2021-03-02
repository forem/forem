Feature: Integrate with Minitest

  To use rspec-mocks with minitest, simply require `rspec/mocks/minitest_integration`.

  Scenario: Use rspec-mocks with Minitest::Test
    Given a file named "test/rspec_mocks_test.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'rspec/mocks/minitest_integration'

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
     When I run `ruby test/rspec_mocks_test.rb --seed 0`
     Then it should fail with the following output:
       |   1) Failure:                                        |
       | RSpecMocksTest#test_failing_positive_expectation     |
       | (Double (anonymous)).message(*(any args))            |
       |     expected: 1 time with any arguments              |
       |     received: 0 times with any arguments             |
       |                                                      |
       |   2) Failure:                                        |
       | RSpecMocksTest#test_failing_negative_expectation     |
       | (Double (anonymous)).message(no args)                |
       |     expected: 0 times with any arguments             |
       |     received: 1 time                                 |
       |                                                      |
       |   3) Failure:                                        |
       | RSpecMocksTest#test_failing_positive_spy_expectation |
       | (Double (anonymous)).james(*(any args))              |
       |     expected: 1 time with any arguments              |
       |     received: 0 times with any arguments             |
       |                                                      |
       |   4) Failure:                                        |
       | RSpecMocksTest#test_failing_negative_spy_expectation |
       | (Double (anonymous)).james(no args)                  |
       |     expected: 0 times with any arguments             |
       |     received: 1 time                                 |
       |                                                      |
       |  8 runs, 0 assertions, 4 failures, 0 errors, 0 skips |

  Scenario: Use rspec-mocks with Minitest::Spec
    Given a file named "spec/rspec_mocks_spec.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'minitest/spec'
      require 'rspec/mocks/minitest_integration'

      describe "Minitest Spec integration" do
        it 'passes a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
          dbl.message
        end

        it 'fails a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
        end

        it 'passes a negative expectation (using to_not)' do
          dbl = double
          expect(dbl).to_not receive(:message)
        end

        it 'fails a negative expectation (using not_to)' do
          dbl = double
          expect(dbl).not_to receive(:message)
          dbl.message
        end
      end
      """
     When I run `ruby spec/rspec_mocks_spec.rb --seed 0`
     Then it should fail with the following output:
       |   1) Failure:                                                                   |
       | Minitest Spec integration#test_0002_fails a positive expectation                |
       | (Double (anonymous)).message(*(any args))                                       |
       |     expected: 1 time with any arguments                                         |
       |     received: 0 times with any arguments                                        |
       |                                                                                 |
       |   2) Failure:                                                                   |
       | Minitest Spec integration#test_0004_fails a negative expectation (using not_to) |
       | (Double (anonymous)).message(no args)                                           |
       |     expected: 0 times with any arguments                                        |
       |     received: 1 time                                                            |
       |                                                                                 |
       |  4 runs, 4 assertions, 2 failures, 0 errors, 0 skips                            |

  Scenario: Load rspec-mocks before rspec-expectations, with Minitest::Spec
    Given a file named "spec/rspec_mocks_spec.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'minitest/spec'
      require 'rspec/mocks/minitest_integration'
      require 'rspec/expectations/minitest_integration'

      describe "Minitest Spec integration" do
        it 'passes a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
          dbl.message
        end

        it 'fails a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
        end

        it 'passes a negative expectation (using to_not)' do
          dbl = double
          expect(dbl).to_not receive(:message)
        end

        it 'fails a negative expectation (using not_to)' do
          dbl = double
          expect(dbl).not_to receive(:message)
          dbl.message
        end

        it 'can use both minitest and rspec expectations' do
          expect(1 + 3).must_equal 4
          expect(1 + 3).to eq 4
        end
      end
      """
     When I run `ruby spec/rspec_mocks_spec.rb --seed 0`
     Then it should fail with the following output:
       |   1) Failure:                                                                   |
       | Minitest Spec integration#test_0002_fails a positive expectation                |
       | (Double (anonymous)).message(*(any args))                                       |
       |     expected: 1 time with any arguments                                         |
       |     received: 0 times with any arguments                                        |
       |                                                                                 |
       |   2) Failure:                                                                   |
       | Minitest Spec integration#test_0004_fails a negative expectation (using not_to) |
       | (Double (anonymous)).message(no args)                                           |
       |     expected: 0 times with any arguments                                        |
       |     received: 1 time                                                            |
       |                                                                                 |
       |  5 runs, 6 assertions, 2 failures, 0 errors, 0 skips                            |

  Scenario: Load rspec-mocks after rspec-expectations, with Minitest::Spec
    Given a file named "spec/rspec_mocks_spec.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'minitest/spec'
      require 'rspec/expectations/minitest_integration'
      require 'rspec/mocks/minitest_integration'

      describe "Minitest Spec integration" do
        it 'passes a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
          dbl.message
        end

        it 'fails a positive expectation' do
          dbl = double
          expect(dbl).to receive(:message)
        end

        it 'passes a negative expectation (using to_not)' do
          dbl = double
          expect(dbl).to_not receive(:message)
        end

        it 'fails a negative expectation (using not_to)' do
          dbl = double
          expect(dbl).not_to receive(:message)
          dbl.message
        end

        it 'can use both minitest and rspec expectations' do
          expect(1 + 3).must_equal 4
          expect(1 + 3).to eq 4
        end
      end
      """
     When I run `ruby spec/rspec_mocks_spec.rb --seed 0`
     Then it should fail with the following output:
       |   1) Failure:                                                                   |
       | Minitest Spec integration#test_0002_fails a positive expectation                |
       | (Double (anonymous)).message(*(any args))                                       |
       |     expected: 1 time with any arguments                                         |
       |     received: 0 times with any arguments                                        |
       |                                                                                 |
       |   2) Failure:                                                                   |
       | Minitest Spec integration#test_0004_fails a negative expectation (using not_to) |
       | (Double (anonymous)).message(no args)                                           |
       |     expected: 0 times with any arguments                                        |
       |     received: 1 time                                                            |
       |                                                                                 |
       |  5 runs, 6 assertions, 2 failures, 0 errors, 0 skips                            |
