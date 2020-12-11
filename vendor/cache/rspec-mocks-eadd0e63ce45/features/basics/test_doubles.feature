Feature: Test Doubles

  _Test double_ is a generic term for any object that stands in for a real object during a test
  (think "stunt double"). You create one using the `double` method. Doubles are "strict" by
  default -- any message you have not allowed or expected will trigger an error -- but you can
  [switch a double to being "loose"](./null-object-doubles). When creating a double, you can allow messages (and set
  their return values) by passing a hash.

  Once you have a test double, you can [allow](./allowing-messages) or [expect](./expecting-messages) messages on it.

  We recommend you use [verifying doubles](../verifying-doubles) whenever possible.

  Scenario: Doubles are strict by default
    Given a file named "double_spec.rb" with:
      """ruby
      RSpec.describe "A test double" do
        it "raises errors when messages not allowed or expected are received" do
          dbl = double("Some Collaborator")
          dbl.foo
        end
      end
      """
     When I run `rspec double_spec.rb`
     Then it should fail with:
      """
      #<Double "Some Collaborator"> received unexpected message :foo with (no args)
      """

  Scenario: A hash can be used to define allowed messages and return values
    Given a file named "double_spec.rb" with:
      """ruby
      RSpec.describe "A test double" do
        it "returns canned responses from the methods named in the provided hash" do
          dbl = double("Some Collaborator", :foo => 3, :bar => 4)
          expect(dbl.foo).to eq(3)
          expect(dbl.bar).to eq(4)
        end
      end
      """
     When I run `rspec double_spec.rb`
     Then the examples should all pass
