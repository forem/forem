By default Mailer specs reside in the `spec/mailers` folder. Adding the metadata
`:type => :mailer` to any context makes its examples be treated as mailer specs.

A mailer spec is a thin wrapper for an ActionMailer::TestCase, and includes all
of the behavior and assertions that it provides, in addition to RSpec's own
behavior and expectations.

## Examples

    require "rails_helper"

    RSpec.describe Notifications, :type => :mailer do
      describe "notify" do
        let(:mail) { Notifications.signup }

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
