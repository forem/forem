require "rails_helper"

RSpec.describe Moderator::MergeUser, type: :service do
  let!(:keep_user) { create(:user) }
  let!(:delete_user) { create(:user) }
  let(:delete_user_id) { delete_user.id }
  let(:admin) { create(:user, :super_admin) }

  describe "#merge" do
    let(:article) { create(:article, user: delete_user) }
    let(:comment) { create(:comment, user: delete_user) }
    let(:reaction) { create(:reaction, user: delete_user, category: "readinglist") }
    let(:article_reaction) { create(:reaction, reactable: article, category: "readinglist") }
    let(:related_records) { [article, comment, reaction, article_reaction] }

    before { sidekiq_perform_enqueued_jobs }

    it "deletes delete_user_id and keeps keep_user" do
      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end
      expect(User.find_by(id: delete_user_id)).to be_nil
      expect(User.find_by(id: keep_user.id)).not_to be_nil
    end

    it "deletes the merged-away user in the background as a merge (not GDPR) deletion" do
      sidekiq_assert_enqueued_with(job: Users::DeleteWorker, args: [delete_user_id, true, "merge"]) do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end
      expect(User.exists?(delete_user_id)).to be(true)
    end

    it "moves the content to keep_user before the merged-away user is deleted", :aggregate_failures do
      related_records

      described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)

      expect(article.reload.user_id).to eq(keep_user.id)
      expect(comment.reload.user_id).to eq(keep_user.id)
      expect(reaction.reload.user_id).to eq(keep_user.id)

      sidekiq_perform_enqueued_jobs(only: Users::DeleteWorker)

      expect(User.exists?(delete_user_id)).to be(false)
      expect(Article.exists?(article.id)).to be(true)
      expect(Comment.exists?(comment.id)).to be(true)
      expect(Reaction.exists?(reaction.id)).to be(true)
      expect(GDPRDeleteRequest.where(user_id: delete_user_id)).to be_empty
    end

    describe "locking the merged-away account until it's deleted" do
      before do
        delete_user.update!(password: "password-123", password_confirmation: "password-123")
        create(:api_secret, user: delete_user)
      end

      def merge
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
        delete_user.reload
      end

      it "locks the account" do
        merge

        expect(delete_user).to be_access_locked
        expect(delete_user).not_to be_active_for_authentication
      end

      it "stops the old password from working" do
        merge

        expect(delete_user.valid_password?("password-123")).to be(false)
      end

      it "invalidates existing sessions and remember-me cookies" do
        session_salt = delete_user.authenticatable_salt
        expect(User.serialize_from_session(delete_user.id, session_salt)).to eq(delete_user)

        merge

        expect(User.serialize_from_session(delete_user.id, session_salt)).to be_nil
      end

      it "revokes the account's API keys" do
        expect { merge }.to change { delete_user.api_secrets.count }.from(1).to(0)
      end

      it "leaves the account alone when the merge is rejected", :aggregate_failures do
        omniauth_mock_github_payload
        omniauth_mock_twitter_payload
        create(:identity, user: delete_user, provider: "github")
        create(:identity, user: delete_user, provider: "twitter")

        expect { merge }.to raise_error(StandardError)

        delete_user.reload
        expect(delete_user).not_to be_access_locked
        expect(delete_user.valid_password?("password-123")).to be(true)
        expect(delete_user.api_secrets.count).to eq(1)
      end

      it "leaves keep_user alone" do
        keep_user.update!(password: "password-456", password_confirmation: "password-456")

        merge

        expect(keep_user.reload).not_to be_access_locked
        expect(keep_user.valid_password?("password-456")).to be(true)
      end
    end

    it "updates badge_achievements_count" do
      create_list(:badge_achievement, 2, user: delete_user)

      sidekiq_perform_enqueued_jobs do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
      end

      expect(keep_user.reload.badge_achievements_count).to eq(2)
    end

    describe "DEV → Core sync events" do
      before do
        allow(Trackable::Registry).to receive(:active_names).and_return([:any])
        allow(Trackable::DispatchWorker).to receive(:perform_async)
        Settings::General.customerio_cdp_enabled = true
        FeatureFlag.enable(:dev_core_user_sync)
      end

      after { FeatureFlag.remove(:dev_core_user_sync) }

      around { |ex| with_trackable_events { ex.run } }

      it "emits user_merged for the kept user carrying the merged-away forem user id" do
        described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "user_merged", [keep_user.id],
                hash_including("merged_forem_user_id" => delete_user_id), anything)
      end

      # A merge deletes the merged-away row via Users::DeleteWorker, but it is
      # not a GDPR erasure — the person's content now lives on keep_user, and
      # Core must merge rather than erase.
      it "does not emit user_gdpr_deleted for the merged-away account" do
        sidekiq_perform_enqueued_jobs(only: Users::DeleteWorker) do
          described_class.call(admin: admin, keep_user: keep_user, delete_user_id: delete_user.id)
        end
        expect(User.exists?(delete_user_id)).to be(false)

        expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
          .with(anything, "user_gdpr_deleted", anything, anything, anything)
      end
    end
  end
end
