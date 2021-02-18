Feature: Stub Defined Constant

  Use `stub_const` to stub constants. When the constant is already defined, the stubbed value
  will replace the original value for the duration of the example.

  Scenario: Stub top-level constant
    Given a file named "stub_const_spec.rb" with:
      """ruby
      FOO = 7

      RSpec.describe "stubbing FOO" do
        it "can stub FOO with a different value" do
          stub_const("FOO", 5)
          expect(FOO).to eq(5)
        end

        it "restores the stubbed constant when the example completes" do
          expect(FOO).to eq(7)
        end
      end
      """
    When I run `rspec stub_const_spec.rb`
    Then the examples should all pass

  Scenario: Stub nested constant
    Given a file named "stub_const_spec.rb" with:
      """ruby
      module MyGem
        class SomeClass
          FOO = 7
        end
      end

      module MyGem
        RSpec.describe SomeClass do
          it "stubs the nested constant when it is fully qualified" do
            stub_const("MyGem::SomeClass::FOO", 5)
            expect(SomeClass::FOO).to eq(5)
          end
        end
      end
      """
    When I run `rspec stub_const_spec.rb`
    Then the examples should all pass

  Scenario: Transfer nested constants
    Given a file named "stub_const_spec.rb" with:
      """ruby
      module MyGem
        class SomeClass
          FOO = 7
        end
      end

      module MyGem
        RSpec.describe SomeClass do
          let(:fake_class) { Class.new }

          it "does not transfer nested constants by default" do
            stub_const("MyGem::SomeClass", fake_class)
            expect { SomeClass::FOO }.to raise_error(NameError)
          end

          it "transfers nested constants when using :transfer_nested_constants => true" do
            stub_const("MyGem::SomeClass", fake_class, :transfer_nested_constants => true)
            expect(SomeClass::FOO).to eq(7)
          end

          it "can specify a list of nested constants to transfer" do
            stub_const("MyGem::SomeClass", fake_class, :transfer_nested_constants => [:FOO])
            expect(SomeClass::FOO).to eq(7)
          end
        end
      end
      """
    When I run `rspec stub_const_spec.rb`
    Then the examples should all pass
