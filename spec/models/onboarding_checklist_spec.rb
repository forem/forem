require "rails_helper"

RSpec.describe OnboardingChecklist do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:checklist) { user.onboarding_checklist }

  before { allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(true) }

  describe "auto-creation" do
    it "is created when a user is created" do
      expect(checklist).to be_present
    end

    it "is not created when setting is disabled" do
      allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(false)
      new_user = create(:user)
      expect(new_user.onboarding_checklist).to be_nil
    end

    it "starts with empty items" do
      expect(checklist.items).to eq({})
    end

    it "starts without completed_at" do
      expect(checklist.completed_at).to be_nil
    end
  end

  describe "#complete_item!" do
    it "marks an item as completed" do
      checklist.complete_item!("fill_out_profile")
      expect(checklist.reload.items["fill_out_profile"]).not_to be_falsey
    end

    it "is idempotent" do
      checklist.complete_item!("fill_out_profile")
      updated_at = checklist.reload.updated_at

      checklist.complete_item!("fill_out_profile")
      expect(checklist.reload.updated_at).to eq(updated_at)
    end

    it "ignores unknown keys" do
      checklist.complete_item!("unknown_key")
      expect(checklist.reload.items).to eq({})
    end

    it "sets completed_at when all items are completed" do
      now = Time.current
      travel_to(now) do
        described_class::ITEM_KEYS.each { |key| checklist.complete_item!(key) }
        expect(checklist.reload.completed_at).to be_within(1.second).of(now)
      end
    end

    it "does not set completed_at when only some items are completed" do
      checklist.complete_item!("fill_out_profile")
      expect(checklist.reload.completed_at).to be_nil
    end
  end

  describe "#item_statuses" do
    it "returns status for all defined items" do
      statuses = checklist.item_statuses
      expect(statuses.length).to eq(described_class::ITEM_KEYS.size)
    end

    it "returns completed: false for incomplete items" do
      statuses = checklist.item_statuses
      expect(statuses).to all(include(completed: false))
    end

    it "returns completed: true for completed items" do
      checklist.complete_item!("fill_out_profile")
      status = checklist.item_statuses.find { |s| s[:key] == "fill_out_profile" }
      expect(status[:completed]).to be(true)
    end

    it "includes action URLs from route helpers" do
      statuses = checklist.item_statuses
      urls = statuses.map { |s| s[:action_url] }
      expect(urls).to all(start_with("/"))
    end

    it "includes i18n label keys" do
      statuses = checklist.item_statuses
      keys = statuses.map { |s| s[:label_i18n_key] }
      expect(keys).to include("views.sidebars.onboarding_progress.items.fill_out_profile")
    end
  end

  describe "#completed_count" do
    it "returns 0 when no items are completed" do
      expect(checklist.completed_count).to eq(0)
    end

    it "returns the correct count after completing items" do
      checklist.complete_item!("fill_out_profile")
      checklist.complete_item!("comment_in_welcome")
      expect(checklist.completed_count).to eq(2)
    end
  end

  describe "#total_count" do
    it "returns the total number of item definitions" do
      expect(checklist.total_count).to eq(described_class::ITEM_KEYS.size)
    end
  end

  describe "#all_completed?" do
    it "returns false when no items are completed" do
      expect(checklist.all_completed?).to be(false)
    end

    it "returns false when some items are completed" do
      checklist.complete_item!("fill_out_profile")
      expect(checklist.all_completed?).to be(false)
    end

    it "returns true when all items are completed" do
      described_class::ITEM_KEYS.each { |key| checklist.complete_item!(key) }
      expect(checklist.all_completed?).to be(true)
    end
  end

  describe "#completed?" do
    it "returns false when completed_at is nil" do
      expect(checklist.completed?).to be(false)
    end

    it "returns true when completed_at is set" do
      described_class::ITEM_KEYS.each { |key| checklist.complete_item!(key) }
      expect(checklist.completed?).to be(true)
    end
  end
end
