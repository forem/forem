Feature: `--init` option

  Use the `--init` option on the command line to generate conventional files for
  an RSpec project. It generates a `.rspec` and `spec/spec_helper.rb` with some
  example settings to get you started.

  These settings treat the case where you run an individual spec file
  differently, using the documentation formatter if no formatter has been
  explicitly set.

  Scenario: Generate `.rspec`
    When I run `rspec --init`
    Then the following files should exist:
      | .rspec |
    And the output should contain "create   .rspec"

  Scenario: `.rspec` file already exists
    Given a file named ".rspec" with:
      """
      --force-color
      """
    When I run `rspec --init`
    Then the output should contain "exist   .rspec"

  Scenario: Accept and use the recommended settings in `spec_helper` (which are initially commented out)
    Given I have a brand new project with no files
      And I have run `rspec --init`
     When I accept the recommended settings by removing `=begin` and `=end` from `spec/spec_helper.rb`
      And I create "spec/addition_spec.rb" with the following content:
        """ruby
        RSpec.describe "Addition" do
          it "works" do
            expect(1 + 1).to eq(2)
          end
        end
        """
      And I create "spec/subtraction_spec.rb" with the following content:
        """ruby
        RSpec.describe "Subtraction" do
          it "works" do
            expect(1 - 1).to eq(0)
          end
        end
        """
     Then the output from `rspec` should not be in documentation format
      But the output from `rspec spec/addition_spec.rb` should be in documentation format
      But the output from `rspec spec/addition_spec.rb --format progress` should not be in documentation format

      And the output from `rspec --pattern 'spec/*ction_spec.rb'` should indicate it ran only the subtraction file
      And the output from `rspec --exclude-pattern 'spec/*dition_spec.rb'` should indicate it ran only the subtraction file
