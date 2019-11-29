require "rails_helper"

RSpec.describe Moderator::BanishUser, type: :service, vcr: {} do
  let(:user) { create(:user, :with_complete_profile) }
  let(:user_without_email) { create(:user, email: nil) }
  let(:admin) { create(:user, :super_admin) }

  describe "banish_user" do
    it "unsubscribe user from newsletters if user has email address" do
      allow(user).to receive(:unsubscribe_from_newsletters)
      described_class.call_banish(user: user, admin: admin)
      expect(user).to have_received(:unsubscribe_from_newsletters).once
    end

    context "with user profile info" do # Split into 2 to make rubocop happy
      it "removes user profile details" do
        expect do
          described_class.call_banish(user: user, admin: admin)
        end.to change(user, :twitter_username).to(nil).and change(user, :github_username).to(nil).
          and change(user, :summary).to("").and change(user, :location).to("").
          and change(user, :education).to("").and change(user, :employer_name).to("").
          and change(user, :employer_url).to("").and change(user, :employment_title).to("").
          and change(user, :mostly_work_with).to("").and change(user, :currently_learning).to("").
          and change(user, :currently_hacking_on).to("").and change(user, :available_for).to("").
          and change(user, :email_public).to(false)
      end

      it "removes a users social-media details" do
        expect do
          described_class.call_banish(user: user, admin: admin)
        end.to change(user, :facebook_url).to(nil).and change(user, :dribbble_url).to(nil).
          and change(user, :medium_url).to(nil).and change(user, :stackoverflow_url).to(nil).
          and change(user, :behance_url).to(nil).and change(user, :linkedin_url).to(nil).
          and change(user, :gitlab_url).to(nil).and change(user, :instagram_url).to(nil).
          and change(user, :mastodon_url).to(nil).and change(user, :twitch_url).to(nil).
          and change(user, :feed_url).to(nil).
          and change { user.reload.profile_image_identifier }.to("https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png")
      end
    end

    it "updates user role to :banned" do
      expect do
        described_class.call_banish(user: user, admin: admin)
      end.to change(user, :banned).to(true)
    end

    it "removes user privileges" do
      described_class.call_banish(user: user, admin: admin)
      expect(user.roles).to eq [Role.find_by(name: :banned)]
    end

    it "deletes user activity" do
      allow(Users::DeleteActivity).to receive(:call)
      described_class.call_banish(user: user, admin: admin)
      expect(Users::DeleteActivity).to have_received(:call).once
    end

    it "deletes user comments" do
      allow(Users::DeleteComments).to receive(:call)
      described_class.call_banish(user: user, admin: admin)
      expect(Users::DeleteComments).to have_received(:call).once
    end

    it "deletes user articles" do
      allow(Users::DeleteArticles).to receive(:call)
      described_class.call_banish(user: user, admin: admin)
      expect(Users::DeleteArticles).to have_received(:call).once
    end

    it "removes user from algolia index" do
      allow(user).to receive(:remove_from_index!)
      described_class.call_banish(user: user, admin: admin)
      expect(user).to have_received(:remove_from_index!).once
      expect(Search::RemoveFromIndexJob).to have_been_enqueued
    end

    it "reassigns username" do
      expect do
        described_class.call_banish(user: user, admin: admin)
      end.to change(user, :name).
        and change(user, :username).
        and change(user, :old_username).
        and change(user, :profile_updated_at)
    end

    it "busts username" do
      allow(CacheBuster).to receive(:bust)
      described_class.call_banish(user: user, admin: admin)
      expect(CacheBuster).to have_received(:bust).with("/#{user.old_username}").once
    end
  end
end
