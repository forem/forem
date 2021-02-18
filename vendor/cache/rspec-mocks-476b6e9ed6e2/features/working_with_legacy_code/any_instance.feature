Feature: Any Instance

  rspec-mocks provides two methods, `allow_any_instance_of` and
  `expect_any_instance_of`, that will allow you to stub or mock any instance of a class. They
  are used in place of [`allow`](../basics/allowing-messages) or [`expect`](../basics/expecting-messages):

  ```ruby
  allow_any_instance_of(Widget).to receive(:name).and_return("Wibble")
  expect_any_instance_of(Widget).to receive(:name).and_return("Wobble")
  ```

  These methods add the appropriate stub or expectation to all instances of `Widget`.

  You can also [configure the responses](../configuring-responses) in the same manner.

  This feature is sometimes useful when working with legacy code, though in general we
  discourage its use for a number of reasons:

  * The `rspec-mocks` API is designed for individual object instances, but this feature
    operates on entire classes of objects. As a result there are some semantically confusing
    edge cases. For example, in `expect_any_instance_of(Widget).to
    receive(:name).twice` it isn't clear whether a specific instance is expected to
    receive `name` twice, or if two receives total are expected. (It's the former.)
  * Using this feature is often a design smell. It may be that your test is trying to do too
    much or that the object under test is too complex.
  * It is the most complicated feature of `rspec-mocks`, and has historically received the
    most bug reports. (None of the core team actively use it, which doesn't help.)

  Scenario: Use `allow_any_instance_of` to stub a method
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "allow_any_instance_of" do
        it "returns the specified value on any instance of the class" do
          allow_any_instance_of(Object).to receive(:foo).and_return(:return_value)

          o = Object.new
          expect(o.foo).to eq(:return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Use `allow_any_instance_of` to stub multiple methods
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "allow_any_instance_of" do
        context "with receive_messages" do
          it "stubs multiple methods" do
            allow_any_instance_of(Object).to receive_messages(:foo => 'foo', :bar => 'bar')

            o = Object.new
            expect(o.foo).to eq('foo')
            expect(o.bar).to eq('bar')
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Stubbing any instance of a class with specific arguments
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "allow_any_instance_of" do
        context "with arguments" do
          it "returns the stubbed value when arguments match" do
            allow_any_instance_of(Object).to receive(:foo).with(:param_one, :param_two).and_return(:result_one)
            allow_any_instance_of(Object).to receive(:foo).with(:param_three, :param_four).and_return(:result_two)

            o = Object.new
            expect(o.foo(:param_one, :param_two)).to eq(:result_one)
            expect(o.foo(:param_three, :param_four)).to eq(:result_two)
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Block implementation is passed the receiver as first arg
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "allow_any_instance_of" do
        it 'yields the receiver to the block implementation' do
          allow_any_instance_of(String).to receive(:slice) do |instance, start, length|
            instance[start, length]
          end

          expect('string'.slice(2, 3)).to eq('rin')
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Use `expect_any_instance_of` to set a message expectation on any instance
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "expect_any_instance_of" do
        before do
          expect_any_instance_of(Object).to receive(:foo)
        end

        it "passes when an instance receives the message" do
          Object.new.foo
        end

        it "fails when no instance receives the message" do
          Object.new.to_s
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then it should fail with the following output:
      | 2 examples, 1 failure |
      | Exactly one instance should have received the following message(s) but didn't: foo |
