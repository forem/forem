Feature: `have_attributes` matcher

  Use the have_attributes matcher to specify that an object's attributes match the expected attributes:

    ```ruby
    Person = Struct.new(:name, :age)
    person = Person.new("Jim", 32)

    expect(person).to have_attributes(:name => "Jim", :age => 32)
    expect(person).to have_attributes(:name => a_string_starting_with("J"), :age => (a_value > 30) )
    ```

  The matcher will fail if actual doesn't respond to any of the expected attributes:

    ```ruby
    expect(person).to have_attributes(:name => "Jim", :color => 'red')
    ```

  Scenario: basic usage
    Given a file named "basic_have_attributes_matcher_spec.rb" with:
      """ruby
      Person = Struct.new(:name, :age)

      RSpec.describe Person.new("Jim", 32) do
        it { is_expected.to have_attributes(:name => "Jim") }
        it { is_expected.to have_attributes(:name => a_string_starting_with("J") ) }
        it { is_expected.to have_attributes(:age => 32) }
        it { is_expected.to have_attributes(:age => (a_value > 30) ) }
        it { is_expected.to have_attributes(:name => "Jim", :age => 32) }
        it { is_expected.to have_attributes(:name => a_string_starting_with("J"), :age => (a_value > 30) ) }
        it { is_expected.not_to have_attributes(:name => "Bob") }
        it { is_expected.not_to have_attributes(:age => 10) }
        it { is_expected.not_to have_attributes(:age => (a_value < 30) ) }

        # deliberate failures
        it { is_expected.to have_attributes(:name => "Bob") }
        it { is_expected.to have_attributes(:age => 10) }

        # fails if any of the attributes don't match
        it { is_expected.to have_attributes(:name => "Bob", :age => 32) }
        it { is_expected.to have_attributes(:name => "Jim", :age => 10) }
        it { is_expected.to have_attributes(:name => "Bob", :age => 10) }
      end
      """
    When I run `rspec basic_have_attributes_matcher_spec.rb`
    Then the output should contain "14 examples, 5 failures"
