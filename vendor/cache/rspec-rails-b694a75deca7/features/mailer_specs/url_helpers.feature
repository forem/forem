Feature: URL helpers in mailer examples

  Mailer specs are marked by `:type => :mailer` or if you have set
  `config.infer_spec_type_from_file_location!` by placing them in `spec/mailers`.

  Scenario: using URL helpers with default options
    Given a file named "config/initializers/mailer_defaults.rb" with:
      """ruby
      Rails.configuration.action_mailer.default_url_options = { :host => 'example.com' }
      """
    And a file named "spec/mailers/notifications_spec.rb" with:
      """ruby
      require 'rails_helper'

      RSpec.describe NotificationsMailer, :type => :mailer do
        it 'should have access to URL helpers' do
          expect { gadgets_url }.not_to raise_error
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: using URL helpers without default options
    Given a file named "config/initializers/mailer_defaults.rb" with:
      """ruby
      # no default options
      """
    And a file named "spec/mailers/notifications_spec.rb" with:
      """ruby
      require 'rails_helper'

      RSpec.describe NotificationsMailer, :type => :mailer do
        it 'should have access to URL helpers' do
          expect { gadgets_url :host => 'example.com' }.not_to raise_error
          expect { gadgets_url }.to raise_error
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass
