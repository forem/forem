Feature: Raising an error

  Use `and_raise` to make the test double raise an error when it receives the message. Any of the following forms are supported:

    * `and_raise(ExceptionClass)`
    * `and_raise("message")`
    * `and_raise(ExceptionClass, "message")`
    * `and_raise(instance_of_an_exception_class)`

  Scenario: Raising an error
    Given a file named "raises_an_error_spec.rb" with:
      """ruby
      RSpec.describe "Making it raise an error" do
        it "raises the provided exception" do
          dbl = double
          allow(dbl).to receive(:foo).and_raise("boom")
          dbl.foo
        end
      end
      """
     When I run `rspec raises_an_error_spec.rb`
     Then it should fail with:
      """
        1) Making it raise an error raises the provided exception
           Failure/Error: dbl.foo

           RuntimeError:
             boom
      """
