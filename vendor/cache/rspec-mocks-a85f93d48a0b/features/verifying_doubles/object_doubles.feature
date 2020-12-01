Feature: Using an object double

  `object_double` can be used to create a double from an existing "template" object, from
  which it verifies that any stubbed methods on the double also exist on the template. This is
  useful for objects that are readily constructable, but may have far-reaching side-effects
  such as talking to a database or external API. In this case, using a double rather than the
  real thing allows you to focus on the communication patterns of the object's interface
  without having to worry about accidentally causing side-effects. Object doubles can also be
  used to verify methods defined on an object using `method_missing`, which is not possible
  with [`instance_double`](./using-an-instance-double).

  In addition, `object_double` can be used with specific constant values, as shown below. This
  is for niche situations, such as when dealing with singleton objects.

  Scenario: doubling an existing object
    Given a file named "spec/user_spec.rb" with:
      """ruby
      class User
        # Don't want to accidentally trigger this!
        def save; sleep 100; end
      end

      def save_user(user)
        "saved!" if user.save
      end

      RSpec.describe '#save_user' do
        it 'renders message on success' do
          user = object_double(User.new, :save => true)
          expect(save_user(user)).to eq("saved!")
        end
      end
      """
    When I run `rspec spec/user_spec.rb`
    Then the examples should all pass

  Scenario: doubling a constant object
    Given a file named "spec/email_spec.rb" with:
      """ruby
      require 'logger'

      module MyApp
        LOGGER = Logger.new("myapp")
      end

      class Email
        def self.send_to(recipient)
          MyApp::LOGGER.info("Sent to #{recipient}")
          # other emailing logic
        end
      end

      RSpec.describe Email do
        it 'logs a message when sending' do
          logger = object_double("MyApp::LOGGER", :info => nil).as_stubbed_const
          Email.send_to('hello@foo.com')
          expect(logger).to have_received(:info).with("Sent to hello@foo.com")
        end
      end
      """
    When I run `rspec spec/email_spec.rb`
    Then the examples should all pass
