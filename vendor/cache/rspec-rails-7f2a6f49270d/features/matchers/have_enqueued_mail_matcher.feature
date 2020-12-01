Feature: have_enqueued_mail matcher

  The `have_enqueued_mail` (also aliased as `enqueue_mail`) matcher is used to check if given mailer was enqueued.

  Background:
    Given active job is available

  Scenario: Checking mailer class and method name
    Given a file named "spec/mailers/user_mailer_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe NotificationsMailer do
        it "matches with enqueued mailer" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            NotificationsMailer.signup.deliver_later
          }.to have_enqueued_mail(NotificationsMailer, :signup)
        end
      end
      """
    When I run `rspec spec/mailers/user_mailer_spec.rb`
    Then the examples should all pass

  Scenario: Checking mailer enqueued time
    Given a file named "spec/mailers/user_mailer_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe NotificationsMailer do
        it "matches with enqueued mailer" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            NotificationsMailer.signup.deliver_later(wait_until: Date.tomorrow.noon)
          }.to have_enqueued_mail.at(Date.tomorrow.noon)
        end
      end
      """
    When I run `rspec spec/mailers/user_mailer_spec.rb`
    Then the examples should all pass
