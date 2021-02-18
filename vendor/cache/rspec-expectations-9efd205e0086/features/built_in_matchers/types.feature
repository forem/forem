Feature: Type matchers

  rspec-expectations includes two matchers to specify types of objects:

    * `expect(obj).to be_kind_of(type)`: calls `obj.kind_of?(type)`, which returns true if
        type is in obj's class hierarchy or is a module and is included in a class in obj's
        class hierarchy.
    * `expect(obj).to be_instance_of(type)`: calls `obj.instance_of?(type)`, which returns
        true if and only if type if obj's class.

  Both of these matchers have aliases:

    ```ruby
    expect(obj).to be_a_kind_of(type)      # same as expect(obj).to be_kind_of(type)
    expect(obj).to be_a(type)              # same as expect(obj).to be_kind_of(type)
    expect(obj).to be_an(type)             # same as expect(obj).to be_kind_of(type)
    expect(obj).to be_an_instance_of(type) # same as expect(obj).to be_instance_of(type)
    ```

  Scenario: be_(a_)kind_of matcher
    Given a file named "be_kind_of_matcher_spec.rb" with:
      """ruby
      module MyModule; end

      class Float
        include MyModule
      end

      RSpec.describe 17.0 do
        # the actual class
        it { is_expected.to be_kind_of(Float) }
        it { is_expected.to be_a_kind_of(Float) }
        it { is_expected.to be_a(Float) }

        # the superclass
        it { is_expected.to be_kind_of(Numeric) }
        it { is_expected.to be_a_kind_of(Numeric) }
        it { is_expected.to be_an(Numeric) }

        # an included module
        it { is_expected.to be_kind_of(MyModule) }
        it { is_expected.to be_a_kind_of(MyModule) }
        it { is_expected.to be_a(MyModule) }

        # negative passing case
        it { is_expected.not_to be_kind_of(String) }
        it { is_expected.not_to be_a_kind_of(String) }
        it { is_expected.not_to be_a(String) }

        # deliberate failures
        it { is_expected.not_to be_kind_of(Float) }
        it { is_expected.not_to be_a_kind_of(Float) }
        it { is_expected.not_to be_a(Float) }
        it { is_expected.not_to be_kind_of(Numeric) }
        it { is_expected.not_to be_a_kind_of(Numeric) }
        it { is_expected.not_to be_an(Numeric) }
        it { is_expected.not_to be_kind_of(MyModule) }
        it { is_expected.not_to be_a_kind_of(MyModule) }
        it { is_expected.not_to be_a(MyModule) }
        it { is_expected.to be_kind_of(String) }
        it { is_expected.to be_a_kind_of(String) }
        it { is_expected.to be_a(String) }
      end
      """
    When I run `rspec be_kind_of_matcher_spec.rb`
    Then the output should contain all of these:
      | 24 examples, 12 failures                   |
      | expected 17.0 not to be a kind of Float    |
      | expected 17.0 not to be a kind of Numeric  |
      | expected 17.0 not to be a kind of MyModule |
      | expected 17.0 to be a kind of String       |

  Scenario: be_(an_)instance_of matcher
    Given a file named "be_instance_of_matcher_spec.rb" with:
      """ruby
      module MyModule; end

      class Float
        include MyModule
      end

      RSpec.describe 17.0 do
        # the actual class
        it { is_expected.to be_instance_of(Float) }
        it { is_expected.to be_an_instance_of(Float) }

        # the superclass
        it { is_expected.not_to be_instance_of(Numeric) }
        it { is_expected.not_to be_an_instance_of(Numeric) }

        # an included module
        it { is_expected.not_to be_instance_of(MyModule) }
        it { is_expected.not_to be_an_instance_of(MyModule) }

        # another class with no relation to the subject's hierarchy
        it { is_expected.not_to be_instance_of(String) }
        it { is_expected.not_to be_an_instance_of(String) }

        # deliberate failures
        it { is_expected.not_to be_instance_of(Float) }
        it { is_expected.not_to be_an_instance_of(Float) }
        it { is_expected.to be_instance_of(Numeric) }
        it { is_expected.to be_an_instance_of(Numeric) }
        it { is_expected.to be_instance_of(MyModule) }
        it { is_expected.to be_an_instance_of(MyModule) }
        it { is_expected.to be_instance_of(String) }
        it { is_expected.to be_an_instance_of(String) }
      end
      """
    When I run `rspec be_instance_of_matcher_spec.rb`
    Then the output should contain all of these:
      | 16 examples, 8 failures                       |
      | expected 17.0 not to be an instance of Float  |
      | expected 17.0 to be an instance of Numeric    |
      | expected 17.0 to be an instance of MyModule   |
      | expected 17.0 to be an instance of String     |
