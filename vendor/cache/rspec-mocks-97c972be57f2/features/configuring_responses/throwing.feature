Feature: Throwing

  Use `and_throw` to make the test double throw the provided symbol, optionally with the provided argument.

    * `and_throw(:symbol)`
    * `and_throw(:symbol, argument)`

  Scenario: Throw a symbol
    Given a file named "and_throw_spec.rb" with:
      """ruby
      RSpec.describe "Making it throw a symbol" do
        it "throws the provided symbol" do
          dbl = double
          allow(dbl).to receive(:foo).and_throw(:hello)

          catch :hello do
            dbl.foo
            fail "should not get here"
          end
        end

        it "includes the provided argument when throwing" do
          dbl = double
          allow(dbl).to receive(:foo).and_throw(:hello, "world")

          arg = catch :hello do
            dbl.foo
            fail "should not get here"
          end

          expect(arg).to eq("world")
        end
      end
      """
     When I run `rspec and_throw_spec.rb`
     Then the examples should all pass
