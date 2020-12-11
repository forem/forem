Feature: Equality matchers

  Ruby exposes several different methods for handling equality:

      a.equal?(b) # object identity - a and b refer to the same object
      a.eql?(b)   # object equivalence - a and b have the same value
      a == b      # object equivalence - a and b have the same value with type conversions

  Note that these descriptions are guidelines but are not forced by the language. Any object
  can implement any of these methods with its own semantics.

  rspec-expectations ships with matchers that align with each of these methods:

    ```ruby
    expect(a).to equal(b) # passes if a.equal?(b)
    expect(a).to eql(b)   # passes if a.eql?(b)
    expect(a).to be == b  # passes if a == b
    ```

  It also ships with two matchers that have more of a DSL feel to them:

    ```ruby
    expect(a).to be(b) # passes if a.equal?(b)
    expect(a).to eq(b) # passes if a == b
    ```

  Scenario: compare using eq (==)
    Given a file named "compare_using_eq.rb" with:
      """ruby
      RSpec.describe "a string" do
        it "is equal to another string of the same value" do
          expect("this string").to eq("this string")
        end

        it "is not equal to another string of a different value" do
          expect("this string").not_to eq("a different string")
        end
      end

      RSpec.describe "an integer" do
        it "is equal to a float of the same value" do
          expect(5).to eq(5.0)
        end
      end
      """
    When I run `rspec compare_using_eq.rb`
    Then the output should contain "3 examples, 0 failures"

  Scenario: compare using ==
    Given a file named "compare_using_==.rb" with:
      """ruby
      RSpec.describe "a string" do
        it "is equal to another string of the same value" do
          expect("this string").to be == "this string"
        end

        it "is not equal to another string of a different value" do
          expect("this string").not_to be == "a different string"
        end
      end

      RSpec.describe "an integer" do
        it "is equal to a float of the same value" do
          expect(5).to be == 5.0
        end
      end
      """
    When I run `rspec compare_using_==.rb`
    Then the output should contain "3 examples, 0 failures"

  Scenario: compare using eql (eql?)
    Given a file named "compare_using_eql.rb" with:
      """ruby
      RSpec.describe "an integer" do
        it "is equal to another integer of the same value" do
          expect(5).to eql(5)
        end

        it "is not equal to another integer of a different value" do
          expect(5).not_to eql(6)
        end

        it "is not equal to a float of the same value" do
          expect(5).not_to eql(5.0)
        end

      end
      """
    When I run `rspec compare_using_eql.rb`
    Then the output should contain "3 examples, 0 failures"

  Scenario: compare using equal (equal?)
    Given a file named "compare_using_equal.rb" with:
      """ruby
      RSpec.describe "a string" do
        it "is equal to itself" do
          string = "this string"
          expect(string).to equal(string)
        end

        it "is not equal to another string of the same value" do
          expect("this string").not_to equal("this string")
        end

        it "is not equal to another string of a different value" do
          expect("this string").not_to equal("a different string")
        end

      end
      """
    When I run `rspec compare_using_equal.rb`
    Then the output should contain "3 examples, 0 failures"

  Scenario: compare using be (equal?)
    Given a file named "compare_using_be.rb" with:
      """ruby
      RSpec.describe "a string" do
        it "is equal to itself" do
          string = "this string"
          expect(string).to be(string)
        end

        it "is not equal to another string of the same value" do
          expect("this string").not_to be("this string")
        end

        it "is not equal to another string of a different value" do
          expect("this string").not_to be("a different string")
        end

      end
      """
    When I run `rspec compare_using_be.rb`
    Then the output should contain "3 examples, 0 failures"

