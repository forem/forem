Feature: Message Chains

  You can use `receive_message_chain` in place of `receive` in certain circumstances
  to stub a chain of messages:

  ```ruby
  allow(double).to receive_message_chain("foo.bar") { :baz }
  allow(double).to receive_message_chain(:foo, :bar => :baz)
  allow(double).to receive_message_chain(:foo, :bar) { :baz }
  ````

  Given any of these three forms:

  ```ruby
  double.foo.bar # => :baz
  ```

  Common use in Rails/ActiveRecord:

  ```ruby
  allow(Article).to receive_message_chain("recent.published") { [Article.new] }
  ```

  `receive_message_chain` is designed to be used with evaluating a response like `and_return`,
  `and_yield` etc. For legacy reasons, parity with `stub_chain` is supported but its uses are
  not considered good practice. Support for `stub_chain` parity may be removed in future versions.

  Customisations like `exactly` (i.e. `exactly(2).times`) are not supported.

  Warning:
  ========

  Chains can be arbitrarily long, which makes it quite painless to violate the Law of Demeter
  in violent ways, so you should consider any use of `receive_message_chain` a code smell.
  Even though not all code smells indicate real problems (think fluent interfaces),
  `receive_message_chain` still results in brittle examples. For example, if you write
  `allow(foo).to receive_message_chain(:bar, :baz => 37)` in a spec and then the
  implementation calls `foo.baz.bar`, the stub will not work.


  Chaining with `receive_message_chain` creates ambiguity in how the chains should
  be applied and applies design pressure on complex interactions in the implementation
  code. As such `receive_message_chain` is not a perfect replacement for `receive`. (see
  [Issue 921](https://github.com/rspec/rspec-mocks/issues/921) for a more detailed
  explanation).  Other mocking methods like `double` and `instance_double` provide a
  better way of testing code with these interactions.

  Scenario: Use `receive_message_chain` on a double
    Given a file named "receive_message_chain_spec.rb" with:
      """ruby
      RSpec.describe "Using receive_message_chain on a double" do
        let(:dbl) { double }

        example "using a string and a block" do
          allow(dbl).to receive_message_chain("foo.bar") { :baz }
          expect(dbl.foo.bar).to eq(:baz)
        end

        example "using symbols and a hash" do
          allow(dbl).to receive_message_chain(:foo, :bar => :baz)
          expect(dbl.foo.bar).to eq(:baz)
        end

        example "using symbols and a block" do
          allow(dbl).to receive_message_chain(:foo, :bar) { :baz }
          expect(dbl.foo.bar).to eq(:baz)
        end
      end
      """
    When I run `rspec receive_message_chain_spec.rb`
    Then the examples should all pass

  Scenario: Use `receive_message_chain` on any instance of a class
    Given a file named "receive_message_chain_spec.rb" with:
      """ruby
      RSpec.describe "Using receive_message_chain on any instance of a class" do
        example "using a string and a block" do
          allow_any_instance_of(Object).to receive_message_chain("foo.bar") { :baz }
          expect(Object.new.foo.bar).to eq(:baz)
        end

        example "using symbols and a hash" do
          allow_any_instance_of(Object).to receive_message_chain(:foo, :bar => :baz)
          expect(Object.new.foo.bar).to eq(:baz)
        end

        example "using symbols and a block" do
          allow_any_instance_of(Object).to receive_message_chain(:foo, :bar) { :baz }
          expect(Object.new.foo.bar).to eq(:baz)
        end
      end
      """
    When I run `rspec receive_message_chain_spec.rb`
    Then the examples should all pass
