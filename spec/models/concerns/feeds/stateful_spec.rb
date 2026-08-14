require "rails_helper"

RSpec.describe Feeds::Stateful do
  # Test via Feeds::ImportLog which includes the concern
  let(:user) { create(:user) }

  describe "valid transitions" do
    it "allows pending → fetching" do
      log = create(:feed_import_log, user: user, status: :pending)
      log.status = :fetching
      expect(log).to be_valid
    end

    it "allows fetching → parsing" do
      log = create(:feed_import_log, user: user, status: :fetching)
      log.status = :parsing
      expect(log).to be_valid
    end

    it "allows parsing → importing" do
      log = create(:feed_import_log, user: user, status: :parsing)
      log.status = :importing
      expect(log).to be_valid
    end

    it "allows importing → completed" do
      log = create(:feed_import_log, user: user, status: :importing)
      log.status = :completed
      expect(log).to be_valid
    end

    it "allows any state → failed" do
      %i[pending fetching parsing importing].each do |initial_status|
        log = create(:feed_import_log, user: user, status: initial_status)
        log.status = :failed
        expect(log).to be_valid, "Expected #{initial_status} → failed to be valid"
      end
    end
  end

  describe "invalid transitions" do
    it "rejects pending → completed" do
      log = create(:feed_import_log, user: user, status: :pending)
      log.status = :completed
      expect(log).not_to be_valid
      expect(log.errors[:status].first).to include("cannot transition from pending to completed")
    end

    it "rejects pending → importing" do
      log = create(:feed_import_log, user: user, status: :pending)
      log.status = :importing
      expect(log).not_to be_valid
    end

    it "rejects completed → anything" do
      log = create(:feed_import_log, user: user, status: :completed)
      log.status = :failed
      expect(log).not_to be_valid
    end

    it "rejects failed → anything" do
      log = create(:feed_import_log, user: user, status: :failed, error_message: "test")
      log.status = :pending
      expect(log).not_to be_valid
    end

    it "rejects fetching → completed (skipping steps)" do
      log = create(:feed_import_log, user: user, status: :fetching)
      log.status = :completed
      expect(log).not_to be_valid
    end
  end

  describe "#transition_to!" do
    it "transitions to a valid state" do
      log = create(:feed_import_log, user: user, status: :pending)
      log.transition_to!(:fetching)
      expect(log.reload).to be_fetching
    end

    it "raises on invalid transition" do
      log = create(:feed_import_log, user: user, status: :pending)
      expect { log.transition_to!(:completed) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "new records" do
    it "allows creating a record with any status" do
      log = build(:feed_import_log, user: user, status: :completed)
      expect(log).to be_valid
    end
  end
end
