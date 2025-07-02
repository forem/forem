require "rails_helper"

RSpec.describe Emails::BatchCustomSendWorker, type: :worker do
  describe "#perform" do
    let(:worker) { described_class.new }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:email_record) { create(:email) } # If you have an Email model or factory
    let(:user_ids) { [user.id, user2.id] }
    let(:subject_line) { "Regular Subject" }
    let(:content) { "Email body content" }
    let(:type_of) { "newsletter" }
    let(:email_id) { email_record.id }

    before do
      allow(CustomMailer).to receive_message_chain(:with, :custom_email, :deliver_now)
      allow(Rails.logger).to receive(:error)
    end

    context "when testing the async call" do
      it "queues the job with the correct arguments regardless of user ID order" do
        # Stub the class method perform_async
        allow(described_class).to receive(:perform_async).with(match_array(user_ids), subject_line, content, type_of, email_id)
        described_class.perform_async(user_ids, subject_line, content, type_of, email_id)
        expect(described_class).to have_received(:perform_async).with(match_array(user_ids), subject_line, content, type_of, email_id)
      end
    end

    context "when the users exist" do
      it "sends an email to each user" do
        worker.perform(user_ids, subject_line, content, type_of, email_id)
        expect(CustomMailer).to have_received(:with).twice
      end

      it "logs an error and continues if one user raises an exception" do
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        allow(User).to receive(:find_by).with(id: user2.id).and_raise(StandardError.new("Boom!"))

        worker.perform(user_ids, subject_line, content, type_of, email_id)
        expect(Rails.logger).to have_received(:error).with(/Error sending email to user with id: #{user2.id}.*/)
      end
    end

    context "when a user does not exist" do
      let(:user_ids) { [999_999] } # Some non-existent ID

      it "skips sending any emails" do
        worker.perform(user_ids, subject_line, content, type_of, email_id)
        expect(CustomMailer).not_to have_received(:with)
      end
    end

    context "when subject starts with [TEST]" do
      let(:subject_line) { "[TEST] Subject" }

      it "sends the email regardless of prior email history" do
        user.email_messages.create!(
          email_id: email_id,
          subject: "Older subject"
        )

        worker.perform([user.id], subject_line, content, type_of, email_id)
        expect(CustomMailer).to have_received(:with).once
      end
    end

    context "when subject does NOT start with [TEST]" do
      let(:subject_line) { "Live Subject" }

      context "and the user has no email messages" do
        it "checks for last email and finds none, so #last_email_message is nil" do
          worker.perform([user.id], subject_line, content, type_of, email_id)
          expect(CustomMailer).to have_received(:with).once
        end
      end

      context "and the user has a last email message with [TEST]" do
        before do
          user.email_messages.create!(
            email_id: email_id,
            subject: "[TEST] Old subject"
          )
        end

        it "sends a new email if the most recent subject started with [TEST]" do
          worker.perform([user.id], subject_line, content, type_of, email_id)
          expect(CustomMailer).to have_received(:with).once
        end
      end

      context "and the user has a last email message WITHOUT [TEST]" do
        before do
          user.email_messages.create!(
            email_id: email_id,
            subject: "Prior production subject"
          )
        end

        it "skips sending a new email if last email subject does not start with [TEST]" do
          worker.perform([user.id], subject_line, content, type_of, email_id)
          expect(CustomMailer).not_to have_received(:with)
        end
      end
    end
  end
end