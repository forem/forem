require "rails_helper"

RSpec.describe Comments::SendEmailNotificationJob, type: :job do
  include_examples "#enqueues_job", "comments_send_email_notification", 1

  describe "#perform_now" do
    context "with comment" do
      let_it_be(:comment) { double }

      before do
        allow(Comment).to receive(:find_by).with(id: 1).and_return(comment)
      end

      it "sends reply email" do
        mailer = double
        allow(mailer).to receive(:deliver_now)
        allow(NotifyMailer).to receive(:new_reply_email).and_return(mailer)

        described_class.perform_now(1)

        expect(NotifyMailer).to have_received(:new_reply_email).with(comment)
        expect(mailer).to have_received(:deliver_now)
      end
    end

    context "without comment" do
      it "does not error" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        allow(NotifyMailer).to receive(:new_reply_email)

        described_class.perform_now(nil)

        expect(NotifyMailer).not_to have_received(:new_reply_email)
      end
    end
  end
end
