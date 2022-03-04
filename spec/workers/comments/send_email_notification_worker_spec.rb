require "rails_helper"

RSpec.describe Comments::SendEmailNotificationWorker, type: :worker do
  let(:worker) { subject }
  let(:mailer_class) { NotifyMailer }
  let(:mailer) { double }
  let(:message_delivery) { double }

  include_examples "#enqueues_on_correct_queue", "mailers", 1

  describe "#perform_now" do
    before do
      allow(mailer_class).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:new_reply_email).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    context "with comment" do
      let(:comment) { double }

      before do
        allow(Comment).to receive(:find_by).with(id: 1).and_return(comment)
      end

      it "sends reply email" do
        worker.perform(1)

        expect(mailer_class).to have_received(:with).with(comment: comment)
        expect(mailer).to have_received(:new_reply_email)
        expect(message_delivery).to have_received(:deliver_now)
      end
    end

    context "without comment" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        worker.perform(nil)

        expect(mailer).not_to have_received(:new_reply_email)
      end
    end
  end
end
