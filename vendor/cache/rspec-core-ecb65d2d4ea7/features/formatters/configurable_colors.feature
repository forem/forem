Feature: Configurable colors

  RSpec allows you to configure the terminal colors used in the text formatters.

  * `failure_color`: Color used when tests fail (default: `:red`)
  * `success_color`: Color used when tests pass (default: `:green`)
  * `pending_color`: Color used when tests are pending (default: `:yellow`)
  * `fixed_color`: Color used when a pending block inside an example passes, but
    was expected to fail (default: `:blue`)
  * `detail_color`: Color used for miscellaneous test details (default: `:cyan`)

  Colors are specified as symbols. Options are `:black`, `:red`, `:green`,
  `:yellow`, `:blue`, `:magenta`, `:cyan`, and `:white`.

  @keep-ansi-escape-sequences
  Scenario: Customizing the failure color
    Given a file named "custom_failure_color_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.failure_color = :magenta
        config.color_mode = :on
      end

      RSpec.describe "failure" do
        it "fails and uses the custom color" do
          expect(2).to eq(4)
        end
      end
      """
      When I run `rspec custom_failure_color_spec.rb --format progress`
      Then the failing example is printed in magenta
