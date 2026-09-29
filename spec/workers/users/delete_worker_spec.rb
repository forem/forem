require "rails_helper"

RSpec.describe Users::DeleteWorker, type: :worker do
  let(:worker) { subject }
  let(:mailer_class) { NotifyMailer }
  let(:mailer) { double }
  let(:message_delivery) { double }

  before do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
  end

  describe "#perform" do
    let!(:user) { create(:user) }
    let(:delete) { Users::Delete }

    context "when user is found" do
      it "deletes the user correctly" do
        worker.perform(user.id)

        expect(User.exists?(id: user.id)).to be(false)
      end

      it "emits user_gdpr_deleted to the DEV → Core sync" do
        allow(Trackable::Registry).to receive(:active_names).and_return([:any])
        allow(Trackable::DispatchWorker).to receive(:perform_async)
        Settings::General.customerio_cdp_enabled = true
        FeatureFlag.enable(:dev_core_user_sync)

        with_trackable_events { worker.perform(user.id) }

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "user_gdpr_deleted", [user.id],
                hash_including("id" => user.id, "email" => user.email, "username" => user.username),
                anything)
      ensure
        FeatureFlag.remove(:dev_core_user_sync)
      end

      it "calls the service when a user is found" do
        allow(delete).to receive(:call)
        worker.perform(user.id)
        expect(delete).to have_received(:call).with(user)
      end

      it "sends the notification" do
        expect do
          worker.perform(user.id)
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "doesn't send a notification for admin triggered deletion" do
        expect do
          worker.perform(user.id, true)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end

      it "sends the correct notification" do
        allow(mailer_class).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:account_deleted_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now)

        worker.perform(user.id)

        expect(mailer_class).to have_received(:with).with(name: user.name, email: user.email)
        expect(mailer).to have_received(:account_deleted_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "creates a gdpr-delete record" do
        expect do
          worker.perform(user.id, true)
        end.to change(GDPRDeleteRequest, :count).by(1)
      end

      # Merges delete the merged-away row through this worker, but nobody
      # requested erasure - the person's content moved to the kept account.
      it "does not create a gdpr-delete record for non-GDPR (merge) deletions" do
        expect do
          worker.perform(user.id, true, "merge")
        end.not_to change(GDPRDeleteRequest, :count)
      end

      it "does not emit user_gdpr_deleted for non-GDPR (merge) deletions" do
        allow(Trackable::Registry).to receive(:active_names).and_return([:any])
        allow(Trackable::DispatchWorker).to receive(:perform_async)
        Settings::General.customerio_cdp_enabled = true
        FeatureFlag.enable(:dev_core_user_sync)

        with_trackable_events { worker.perform(user.id, true, "merge") }

        expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
          .with(anything, "user_gdpr_deleted", anything, anything, anything)
      ensure
        FeatureFlag.remove(:dev_core_user_sync)
      end

      it "still deletes the user on non-GDPR (merge) deletions" do
        worker.perform(user.id, true, "merge")

        expect(User.exists?(id: user.id)).to be(false)
      end
    end

    context "when the deletion fails" do
      before do
        allow(ForemStatsClient).to receive(:count)
        allow(delete).to receive(:call).and_raise(ActiveRecord::QueryCanceled, "statement timeout")
      end

      it "re-raises the error so Sidekiq retries the deletion" do
        expect { worker.perform(user.id, true) }.to raise_error(ActiveRecord::QueryCanceled)
      end

      it "records the failure" do
        expect { worker.perform(user.id, true) }.to raise_error(ActiveRecord::QueryCanceled)

        expect(ForemStatsClient).to have_received(:count)
          .with("users.delete", 1, tags: ["action:failed", "user_id:#{user.id}"])
      end

      it "doesn't create a gdpr-delete record or notify the user" do
        expect do
          expect { worker.perform(user.id) }.to raise_error(ActiveRecord::QueryCanceled)
        end.to not_change(GDPRDeleteRequest, :count).and not_change(ActionMailer::Base.deliveries, :count)
      end

      it "records the failure even when looking the user up fails" do
        allow(User).to receive(:find_by).and_raise(ActiveRecord::ConnectionTimeoutError)

        expect { worker.perform(user.id, true) }.to raise_error(ActiveRecord::ConnectionTimeoutError)
        expect(ForemStatsClient).to have_received(:count)
          .with("users.delete", 1, tags: ["action:failed", "user_id:#{user.id}"])
      end
    end

    it "finishes the deletion when a failed attempt is retried", :aggregate_failures do
      article = create(:article, user: user)
      allow(Users::DeletePodcasts).to receive(:call).and_raise(ActiveRecord::QueryCanceled)

      expect { worker.perform(user.id, true) }.to raise_error(ActiveRecord::QueryCanceled)
      expect(User.exists?(user.id)).to be(true)
      expect(Article.exists?(article.id)).to be(false)

      allow(Users::DeletePodcasts).to receive(:call).and_call_original

      expect do
        worker.perform(user.id, true)
      end.to change(GDPRDeleteRequest, :count).by(1)
      expect(User.exists?(user.id)).to be(false)
    end

    it "is retried by Sidekiq" do
      expect(described_class.get_sidekiq_options["retry"]).to eq(10)
    end

    context "when user is not found" do
      it "doesn't fail" do
        worker.perform(-1)
      end

      it "doesn't send the notification" do
        expect do
          worker.perform(-1)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
