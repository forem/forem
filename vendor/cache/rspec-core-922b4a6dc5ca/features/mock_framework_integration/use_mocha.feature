Feature: mock with mocha

  Configure RSpec to use mocha as shown in the scenarios below.

  Scenario: Passing message expectation
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :mocha
      end

      RSpec.describe "mocking with RSpec" do
        it "passes when it should" do
          receiver = mock('receiver')
          receiver.expects(:message).once
          receiver.message
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Failing message expectation
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :mocha
      end

      RSpec.describe "mocking with RSpec" do
        it "fails when it should" do
          receiver = mock('receiver')
          receiver.expects(:message).once
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 1 failure"

  Scenario: Failing message expectation in pending example (remains pending)
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :mocha
      end

      RSpec.describe "failed message expectation in a pending example" do
        it "is listed as pending" do
          pending
          receiver = mock('receiver')
          receiver.expects(:message).once
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failures, 1 pending"
    And the exit status should be 0

  Scenario: Passing message expectation in pending example (fails)
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :mocha
      end

      RSpec.describe "passing message expectation in a pending example" do
        it "fails with FIXED" do
          pending
          receiver = mock('receiver')
          receiver.expects(:message).once
          receiver.message
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "FIXED"
    Then the output should contain "1 example, 1 failure"
    And the exit status should be 1

  Scenario: Accessing `RSpec.configuration.mock_framework.framework_name`
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :mocha
      end

      RSpec.describe "RSpec.configuration.mock_framework.framework_name" do
        it "returns :mocha" do
          expect(RSpec.configuration.mock_framework.framework_name).to eq(:mocha)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

