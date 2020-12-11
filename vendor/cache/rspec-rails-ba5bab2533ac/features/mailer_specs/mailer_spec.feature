Feature: mailer spec

  Scenario: simple passing example
    Given a file named "spec/mailers/notifications_mailer_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe NotificationsMailer, :type => :mailer do
        describe "notify" do
          let(:mail) { NotificationsMailer.signup }

          it "renders the headers" do
            expect(mail.subject).to eq("Signup")
            expect(mail.to).to eq(["to@example.org"])
            expect(mail.from).to eq(["from@example.com"])
          end

          it "renders the body" do
            expect(mail.body.encoded).to match("Hi")
          end
        end
      end
      """
    When I run `rspec spec`
    Then the example should pass
