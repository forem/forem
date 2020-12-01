Feature: let and let!

  Use `let` to define a memoized helper method. The value will be cached across
  multiple calls in the same example but not across examples.

  Note that `let` is lazy-evaluated: it is not evaluated until the first time
  the method it defines is invoked. You can use `let!` to force the method's
  invocation before each example.

  By default, `let` is threadsafe, but you can configure it not to be
  by disabling `config.threadsafe`, which makes `let` perform a bit faster.

  Scenario: Use `let` to define memoized helper method
    Given a file named "let_spec.rb" with:
      """ruby
      $count = 0
      RSpec.describe "let" do
        let(:count) { $count += 1 }

        it "memoizes the value" do
          expect(count).to eq(1)
          expect(count).to eq(1)
        end

        it "is not cached across examples" do
          expect(count).to eq(2)
        end
      end
      """
    When I run `rspec let_spec.rb`
    Then the examples should all pass

  Scenario: Use `let!` to define a memoized helper method that is called in a `before` hook
    Given a file named "let_bang_spec.rb" with:
      """ruby
      $count = 0
      RSpec.describe "let!" do
        invocation_order = []

        let!(:count) do
          invocation_order << :let!
          $count += 1
        end

        it "calls the helper method in a before hook" do
          invocation_order << :example
          expect(invocation_order).to eq([:let!, :example])
          expect(count).to eq(1)
        end
      end
      """
    When I run `rspec let_bang_spec.rb`
    Then the examples should all pass
