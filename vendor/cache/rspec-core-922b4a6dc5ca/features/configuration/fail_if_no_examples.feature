Feature: fail if no examples

  Use the `fail_if_no_examples` option to make RSpec exit with a failure status (by default 1) if there are no examples. Using this option, it is recommended to add a `--require spec_helper` option to `.rspec` file to ensure the `fail_if_no_examples` option is set even if no spec files are loaded.

  This option may be particularly useful when you happen to not run RSpec tests locally, but rely on CI to do this. This prevents from false positive builds, when you expected some RSpec examples to be run, but none were run. Such a situation may be caused by your misconfiguration or regression/major changes in RSpec.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.fail_if_no_examples = true }
      """
    Given a file named ".rspec" with:
      """ruby
      --require spec_helper
      """
    Given a file named "spec/some.spec.rb" with:
      """ruby
      RSpec.describe 'something' do
        it 'succeeds' do
          true
        end
      end
      """

  Scenario: Examples file name is not matched by RSpec pattern, thus there are no examples run
    When I run `rspec`
    Then it should fail with "0 examples, 0 failures"

  Scenario: Examples file name is matched by RSpec pattern, 1 example is run
    When I run `rspec --pattern spec/**/*.spec.rb`
    Then it should pass with "1 example, 0 failures"
