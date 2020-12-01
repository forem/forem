Feature: Scope

  All rspec-mocks constructs have a per-example lifecycle. Message expectations are verified
  after each example. Doubles, method stubs, stubbed constants, etc. are all cleaned up after
  each example. This ensures that each example can be run in isolation, and in any order.

  It is perfectly fine to set up doubles, stubs, and message expectations in a
  `before(:example)` hook, as that hook is executed in the scope of the example:

  ```ruby
  before(:example) do
    allow(MyClass).to receive(:foo)
  end
  ```

  Since `before(:context)` runs outside the scope of any individual example, usage of
  rspec-mocks features is not supported there. You can, however, create a temporary scope in
  _any_ arbitrary context, including in a `before(:context)` hook, using
  `RSpec::Mocks.with_temporary_scope { }`.

  Scenario: Cannot create doubles in a `before(:context)` hook
    Given a file named "before_context_spec.rb" with:
      """ruby
      RSpec.describe "Creating a double in a before(:context) hook" do
        before(:context) do
          @dbl = double(:foo => 13)
        end

        it "fails before it gets to the examples" do
          expect(@dbl.foo).to eq(13)
        end
      end
      """
    When I run `rspec before_context_spec.rb`
    Then it should fail with:
      """
      The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported.
      """

  Scenario: Use `with_temporary_scope` to create and use a double in a `before(:context)` hook
    Given a file named "with_temporary_scope_spec.rb" with:
      """ruby
      RSpec.describe "Creating a double in a before(:context) hook" do
        before(:context) do
          RSpec::Mocks.with_temporary_scope do
            dbl = double(:foo => 13)
            @result = dbl.foo
          end
        end

        it "allows a double to be created and used from within a with_temporary_scope block" do
          expect(@result).to eq(13)
        end
      end
      """
    When I run `rspec with_temporary_scope_spec.rb`
    Then the examples should all pass

  Scenario: Doubles cannot be reused in another example
    Given a file named "leak_test_double_spec.rb" with:
      """ruby
      class Account
        class << self
          attr_accessor :logger
        end

        def initialize
          @balance = 0
        end

        attr_reader :balance

        def credit(amount)
          @balance += amount
          self.class.logger.log("Credited $#{amount}")
        end
      end

      RSpec.describe Account do
        it "logs each credit" do
          Account.logger = logger = double("Logger")
          expect(logger).to receive(:log).with("Credited $15")
          account = Account.new
          account.credit(15)
        end

        it "keeps track of the balance" do
          account = Account.new
          expect { account.credit(10) }.to change { account.balance }.by(10)
        end
      end
      """
    When I run `rspec leak_test_double_spec.rb`
    Then it should fail with the following output:
      | 2 examples, 1 failure                                                                                                         |
      |                                                                                                                               |
      |  1) Account keeps track of the balance                                                                                        |
      |     Failure/Error: self.class.logger.log("Credited $#{amount}")                                                               |
      |       #<Double "Logger"> was originally created in one example but has leaked into another example and can no longer be used. |
