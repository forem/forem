Feature: Using a class double

  `class_double` is provided as a complement to [`instance_double`](./using-an-instance-double) with the difference that it
  verifies _class_ methods on the given class rather than instance methods.

  In addition, it also provides a convenience method `as_stubbed_const` to replace concrete
  classes with the defined double. See [mutating constants](../mutating-constants) for more details.

  Note: `class_double` can be used for modules as well. We chose to stick with the
  `class_double` terminology because the methods a `class_double` verifies against are
  commonly called "class methods", not "module methods", even when working with a module.

  Background:
    Given a file named "lib/user.rb" with:
      """ruby
      class User
        def suspend!
          ConsoleNotifier.notify("suspended as")
        end
      end
      """

    Given a file named "lib/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
        MAX_WIDTH = 80

        def self.notify(message)
          puts message
        end
      end
      """

    Given a file named "spec/user_spec.rb" with:
      """ruby
      require 'user'
      require 'console_notifier'

      RSpec.describe User, '#suspend!' do
        it 'notifies the console' do
          notifier = class_double("ConsoleNotifier").
            as_stubbed_const(:transfer_nested_constants => true)

          expect(notifier).to receive(:notify).with("suspended as")
          expect(ConsoleNotifier::MAX_WIDTH).to eq(80)

          user = User.new
          user.suspend!
        end
      end
      """

  Scenario: replacing existing constants
    When I run `rspec spec/user_spec.rb`
    Then the examples should all pass

  Scenario: renaming `ConsoleNotifier.notify` to `send_notification`
    Given a file named "lib/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
        MAX_WIDTH = 80

        def self.send_notification(message)
          puts message
        end
      end
      """
    When I run `rspec spec/user_spec.rb`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "the ConsoleNotifier class does not implement the class method:"
