require "rails_helper"

RSpec.describe Comments::SendEmailNotificationWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "mailers", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with comment" do
      let_it_be(:comment) { double }

      before do
        allow(Comment).to receive(:find_by).with(id: 1).and_return(comment)
      end

      it "sends reply email" do
        mailer = double
        allow(mailer).to receive(:deliver_now)
        allow(NotifyMailer).to receive(:new_reply_email).and_return(mailer)

        worker.perform(1)

        expect(NotifyMailer).to have_received(:new_reply_email).with(comment)
        expect(mailer).to have_received(:deliver_now)
      end
    end

    context "without comment" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        allow(NotifyMailer).to receive(:new_reply_email)

        worker.perform(nil)

        expect(NotifyMailer).not_to have_received(:new_reply_email)
      end
    end
  end
end
