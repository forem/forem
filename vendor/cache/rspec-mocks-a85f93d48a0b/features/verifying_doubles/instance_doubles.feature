Feature: Using an instance double

  An `instance_double` is the most common type of verifying double. It takes a class name or
  object as its first argument, then verifies that any methods being stubbed would be present
  on an _instance_ of that class. In addition, when it receives messages, it verifies that the
  provided arguments are supported by the method signature, both in terms of arity and
  allowed or required keyword arguments, if any. The same argument verification happens
  when you [constrain the arguments](../setting-constraints/matching-arguments) using `with`.

  For methods handled by `method_missing`, see [dynamic classes](./dynamic-classes).

  Background:
    Given a file named "app/models/user.rb" with:
      """ruby
      class User < Struct.new(:notifier)
        def suspend!
          notifier.notify("suspended as")
        end
      end
      """

    Given a file named "spec/unit_helper.rb" with:
      """ruby
      $LOAD_PATH.unshift("app/models")
      """

    Given a file named "spec/spec_helper.rb" with:
      """ruby
      require 'unit_helper'

      require 'user'
      require 'console_notifier'

      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|

          # This option should be set when all dependencies are being loaded
          # before a spec run, as is the case in a typical spec helper. It will
          # cause any verifying double instantiation for a class that does not
          # exist to raise, protecting against incorrectly spelt names.
          mocks.verify_doubled_constant_names = true

        end
      end
      """

    Given a file named "spec/unit/user_spec.rb" with:
      """ruby
      require 'unit_helper'

      require 'user'

      RSpec.describe User, '#suspend!' do
        it 'notifies the console' do
          notifier = instance_double("ConsoleNotifier")

          expect(notifier).to receive(:notify).with("suspended as")

          user = User.new(notifier)
          user.suspend!
        end
      end
      """

  Scenario: spec passes in isolation
    When I run `rspec spec/unit/user_spec.rb`
    Then the examples should all pass

  Scenario: spec passes with dependencies loaded and method implemented
    Given a file named "app/models/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
        def notify(msg)
          puts message
        end
      end
      """

    When I run `rspec -r./spec/spec_helper spec/unit/user_spec.rb`
    Then the examples should all pass

  Scenario: spec fails with dependencies loaded and method unimplemented
    Given a file named "app/models/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
      end
      """
    When I run `rspec -r./spec/spec_helper spec/unit/user_spec.rb`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "ConsoleNotifier class does not implement the instance method:"

  Scenario: spec fails with dependencies loaded and incorrect arity
    Given a file named "app/models/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
        def notify(msg, color)
          puts color + message
        end
      end
      """
    When I run `rspec -r./spec/spec_helper spec/unit/user_spec.rb`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "Wrong number of arguments."
