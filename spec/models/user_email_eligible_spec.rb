require "rails_helper"

RSpec.describe "User email eligibility", type: :model do
  describe "sync_base_email_eligible!" do
    let!(:user) { create(:user, registered: true) }

    before do
      user.update!(email: "test@example.com")
      user.notification_setting.update!(email_newsletter: true)
      user.sync_base_email_eligible!
    end

    it "sets base_email_eligible to true when user meets all criteria" do
      expect(user.base_email_eligible).to eq(true)
    end

    it "sets to false when not registered" do
      user.update!(registered: false)
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to false when email is blank" do
      user.update!(email: "")
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to false when suspended" do
      user.add_role(:suspended)
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to false when spam" do
      user.add_role(:spam)
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to false when email_newsletter is false" do
      user.notification_setting.update!(email_newsletter: false)
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to false when score is below zero" do
      user.update!(score: -1)
      expect(user.base_email_eligible).to eq(false)
    end

    it "sets to true when score is directly set to zero or above" do
      user.update!(score: 0)
      expect(user.base_email_eligible).to eq(true)
      user.update!(score: 1)
      expect(user.base_email_eligible).to eq(true)
    end

    it "syncs correctly when role is removed" do
      user.add_role(:suspended)
      expect(user.base_email_eligible).to eq(false)

      user.remove_role(:suspended)
      expect(user.base_email_eligible).to eq(true)
    end
  end

  describe "automatic synchronization callbacks" do
    let(:user) { create(:user, registered: true, email: "start@example.com") }

    before do
      user.notification_setting.update!(email_newsletter: true)
      # Ensure it's true initially
      expect(user.reload.base_email_eligible).to eq(true)
    end

    it "syncs when email is updated" do
      user.update!(email: "")
      expect(user.base_email_eligible).to eq(false)

      user.email = "fixed@example.com"
      user.skip_confirmation_notification! if user.respond_to?(:skip_confirmation_notification!)
      user.skip_reconfirmation! if user.respond_to?(:skip_reconfirmation!)
      user.save!
      expect(user.base_email_eligible).to eq(true)
    end

    it "syncs when email is cleared out via update_attribute" do
      user.update_attribute(:email, nil)
      expect(user.base_email_eligible).to eq(false)
    end

    it "syncs when registered status changes" do
      user.update!(registered: false)
      expect(user.base_email_eligible).to eq(false)
    end

    it "syncs when suspended role is added or removed" do
      user.add_role(:suspended)
      expect(user.base_email_eligible).to eq(false)

      user.remove_role(:suspended)
      expect(user.base_email_eligible).to eq(true)
    end

    it "syncs when spam role is added or removed" do
      user.add_role(:spam)
      expect(user.base_email_eligible).to eq(false)

      user.remove_role(:spam)
      expect(user.base_email_eligible).to eq(true)
    end

    it "syncs when email_newsletter setting is changed" do
      user.notification_setting.update!(email_newsletter: false)
      # Need to reload user because notification_setting is touching it but the instance here might be stale
      expect(user.reload.base_email_eligible).to eq(false)

      user.notification_setting.update!(email_newsletter: true)
      expect(user.reload.base_email_eligible).to eq(true)
    end

    it "syncs when score is updated" do
      user.update!(score: -10)
      expect(user.reload.base_email_eligible).to eq(false)

      user.update!(score: 10)
      expect(user.reload.base_email_eligible).to eq(true)
    end
  end

  describe ".email_eligible scope" do
    let!(:eligible_user) do
      create(:user, registered: true, email: "eligible@example.com").tap do |u|
        u.notification_setting.update!(email_newsletter: true)
      end
    end

    let!(:ineligible_user) do
      create(:user, registered: true, email: "ineligible@example.com").tap do |u|
        u.notification_setting.update!(email_newsletter: false)
      end
    end

    let!(:negative_score_user) do
      create(:user, registered: true, email: "negative@example.com", score: -10).tap do |u|
        u.notification_setting.update!(email_newsletter: true)
      end
    end

    context "when USE_BASE_EMAIL_ELIGIBLE_COLUMN is true" do
      before do
        stub_const("ENV", ENV.to_hash.merge("USE_BASE_EMAIL_ELIGIBLE_COLUMN" => "true"))
      end

      it "uses the base_email_eligible column" do
        # We manually update one parameter without firing callbacks to truly test the column itself
        eligible_user.update_column(:base_email_eligible, true)
        ineligible_user.update_column(:base_email_eligible, false)
        negative_score_user.update_column(:base_email_eligible, false)

        expect(User.email_eligible).to include(eligible_user)
        expect(User.email_eligible).not_to include(ineligible_user)
        expect(User.email_eligible).not_to include(negative_score_user)
      end
    end

    context "when USE_BASE_EMAIL_ELIGIBLE_COLUMN is false or nil" do
      before do
        stub_const("ENV", ENV.to_hash.merge("USE_BASE_EMAIL_ELIGIBLE_COLUMN" => nil))
      end

      it "uses the legacy associations" do
        expect(User.email_eligible).to include(eligible_user)
        expect(User.email_eligible).not_to include(ineligible_user)
        expect(User.email_eligible).not_to include(negative_score_user)
      end
    end
  end
end
