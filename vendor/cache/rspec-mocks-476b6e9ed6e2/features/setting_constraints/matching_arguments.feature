Feature: Matching arguments

  Use `with` to specify the expected arguments. A [message expectation](../basics/expecting-messages) constrained by `with`
  will only be satisfied when called with matching arguments. A canned response for an
  [allowed message](../basics/allowing-messages) will only be used when the arguments match.

  | To match...                                         | ...use an expression like:         | ...which matches calls like:          |
  | --------------------------------------------------- | ---------------------------------  | ------------------------------------- |
  | Literal arguments                                   | `with(1, true)`                    | `foo(1, true)`                        |
  | Anything that supports case equality (`===`)        | `with(/bar/)`                      | `foo("barn")`                         |
  | Any list of args                                    | `with(any_args)`                   | `foo()`<br>`foo(1)`<br>`foo(:bar, 2)` |
  | Any sublist of args (like an arg splat)             | `with(1, any_args)`                | `foo(1)`<br>`foo(1, :bar, :bazz)`     |
  | An empty list of args                               | `with(no_args)`                    | `foo()`                               |
  | Anything for a given positional arg                 | `with(3, anything)`                | `foo(3, nil)`<br>`foo(3, :bar)`       |
  | Against an interface                                | `with(duck_type(:each))`           | `foo([])`                             |
  | A boolean                                           | `with(3, boolean)`                 | `foo(3, true)`<br>`foo(3, false)`     |
  | A subset of a hash                                  | `with(hash_including(:a => 1))`    | `foo(:a => 1, :b => 2)`               |
  | An excluded subset of a hash                        | `with(hash_excluding(:a => 1))`    | `foo(:b => 2)`                        |
  | A subset of an array                                | `with(array_including(:a, :b))`    | `foo([:a, :b, :c])`                   |
  | An instance of a specific class                     | `with(instance_of(Integer))`       |  `foo(3)`                             |
  | An object with a given module in its ancestors list | `with(kind_of(Numeric))`           | `foo(3)`                              |
  | An object with matching attributes                  | `with(having_attributes(:a => 1))` | `foo(:a => 1, :b => 2)`               |
  | Any RSpec matcher                                   | `with(<matcher>)`                  | `foo(<object that matches>)`          |

  Scenario: Basic example
    Given a file named "basic_example_spec.rb" with:
      """ruby
      RSpec.describe "Constraining a message expectation using with" do
        let(:dbl) { double }
        before { expect(dbl).to receive(:foo).with(1, anything, /bar/) }

        it "passes when the args match" do
          dbl.foo(1, nil, "barn")
        end

        it "fails when the args do not match" do
          dbl.foo(1, nil, "other")
        end
      end
      """
    When I run `rspec basic_example_spec.rb`
    Then it should fail with the following output:
      | 2 examples, 1 failure                                           |
      |                                                                 |
      | Failure/Error: dbl.foo(1, nil, "other")                         |
      |   #<Double (anonymous)> received :foo with unexpected arguments |
      |     expected: (1, anything, /bar/)                              |
      |          got: (1, nil, "other")                                 |

  Scenario: Using a RSpec matcher
    Given a file named "rspec_matcher_spec.rb" with:
      """ruby
      RSpec.describe "Using a RSpec matcher" do
        let(:dbl) { double }
        before { expect(dbl).to receive(:foo).with(a_collection_containing_exactly(1, 2)) }

        it "passes when the args match" do
          dbl.foo([2, 1])
        end

        it "fails when the args do not match" do
          dbl.foo([1, 3])
        end
      end
      """
    When I run `rspec rspec_matcher_spec.rb`
    Then it should fail with the following output:
      | 2 examples, 1 failure                                         |
      |                                                               |
      | Failure/Error: dbl.foo([1, 3])                                |
      | #<Double (anonymous)> received :foo with unexpected arguments |
      | expected: (a collection containing exactly 1 and 2)           |
      | got: ([1, 3])                                                 |

  Scenario: Using a custom matcher
    Given a file named "custom_matcher_spec.rb" with:
      """ruby
      RSpec::Matchers.define :a_multiple_of do |x|
        match { |actual| (actual % x).zero? }
      end

      RSpec.describe "Using a custom matcher" do
        let(:dbl) { double }
        before { expect(dbl).to receive(:foo).with(a_multiple_of(3)) }

        it "passes when the args match" do
          dbl.foo(12)
        end

        it "fails when the args do not match" do
          dbl.foo(13)
        end
      end
      """
    When I run `rspec custom_matcher_spec.rb`
    Then it should fail with the following output:
      | 2 examples, 1 failure                                           |
      |                                                                 |
      | Failure/Error: dbl.foo(13)                                      |
      |   #<Double (anonymous)> received :foo with unexpected arguments |
      |     expected: (a multiple of 3)                                 |
      |          got: (13)                                              |

  Scenario: Responding differently based on the arguments
    Given a file named "responding_differently_spec.rb" with:
      """ruby
      RSpec.describe "Using #with to constrain responses" do
        specify "its response depends on the arguments" do
          dbl = double

          # Set a default for any unmatched args
          allow(dbl).to receive(:foo).and_return(:default)

          allow(dbl).to receive(:foo).with(1).and_return(1)
          allow(dbl).to receive(:foo).with(2).and_return(2)

          expect(dbl.foo(0)).to eq(:default)
          expect(dbl.foo(1)).to eq(1)
          expect(dbl.foo(2)).to eq(2)
        end
      end
      """
    When I run `rspec responding_differently_spec.rb`
    Then the examples should all pass
