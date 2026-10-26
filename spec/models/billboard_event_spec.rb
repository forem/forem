require "rails_helper"

RSpec.describe BillboardEvent do
  it { is_expected.to validate_inclusion_of(:category).in_array(described_class::VALID_CATEGORIES) }

  it { is_expected.to validate_inclusion_of(:context_type).in_array(described_class::VALID_CONTEXT_TYPES) }

  describe "#unique_on_user_if_type_of_conversion_category" do
    let(:user) { create(:user) }
    let(:billboard_event) { build(:billboard_event, category: "signup", user: user) }

    it "adds an error if user has already converted a signup" do
      create(:billboard_event, category: "signup", user: user)
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("has already converted")
    end

    it "adds an error if user has already converted a conversion" do
      create(:billboard_event, category: "conversion", user: user)
      billboard_event.category = "conversion"
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("has already converted")
    end

    it "does not add an error if not a signup or conversion" do
      billboard_event.category = "click"
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to be_empty
    end
  end

  describe "#only_recent_registrations" do
    let(:user) { create(:user, registered_at: 2.days.ago) }
    let(:billboard_event) { build(:billboard_event, category: "signup", user: user) }

    it "adds an error if user is not a recent registration" do
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to include("is not a recent registration")
    end

    it "does not add an error if user is a recent registration" do
      user.update(registered_at: 23.hours.ago)
      billboard_event.valid?
      expect(billboard_event.errors[:user_id]).to be_empty
    end
  end

  describe ".add_impression_seconds" do
    context "with an impression last updated 10 seconds ago" do
      let(:user) { create(:user) }
      let(:now) { Time.current }
      let!(:event) do
        create(:billboard_event, category: "impression", user: user, seconds_visible: 10, updated_at: 10.seconds.ago)
      end

      it "adds 10 seconds, touches updated_at, and returns the updated row count" do
        expect(described_class.add_impression_seconds(id: event.id, user_id: user.id, now: now)).to eq(1)
        event.reload
        expect(event.seconds_visible).to eq(20)
        expect(event.updated_at).to be_within(1.second).of(now)
      end

      it "does not update an event updated within the last 9 seconds" do
        event.update_column(:updated_at, 8.seconds.ago)
        expect(described_class.add_impression_seconds(id: event.id, user_id: user.id)).to eq(0)
        expect(event.reload.seconds_visible).to eq(10)
      end

      it "does not update another user's event" do
        other_user = create(:user)
        expect(described_class.add_impression_seconds(id: event.id, user_id: other_user.id)).to eq(0)
        expect(described_class.add_impression_seconds(id: event.id, user_id: nil)).to eq(0)
        expect(event.reload.seconds_visible).to eq(10)
      end

      it "updates an anonymous event for any viewer" do
        event.update_column(:user_id, nil)
        expect(described_class.add_impression_seconds(id: event.id, user_id: nil)).to eq(1)
        expect(event.reload.seconds_visible).to eq(20)
      end

      it "does not update a non-impression event" do
        event.update_column(:category, "click")
        expect(described_class.add_impression_seconds(id: event.id, user_id: user.id)).to eq(0)
        expect(event.reload.seconds_visible).to eq(10)
      end

      it "returns 0 without querying for a blank id" do
        allow(described_class.connection).to receive(:exec_update).and_call_original
        expect(described_class.add_impression_seconds(id: "", user_id: user.id)).to eq(0)
        expect(described_class.connection).not_to have_received(:exec_update)
      end

      it "sends synchronous_commit off and the UPDATE as a single statement" do
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          described_class.add_impression_seconds(id: event.id, user_id: user.id)
        end

        expect(queries.size).to eq(1)
        expect(queries.first).to start_with("SET LOCAL synchronous_commit TO OFF; UPDATE")
      end
    end

    context "when not inside a transaction" do
      self.use_transactional_tests = false

      # No records are created here: the statement runs against an id that cannot exist, so
      # there is nothing to clean up, and the implicit transaction is all that scopes SET LOCAL.
      it "does not leave synchronous_commit off on the connection" do
        connection = described_class.connection
        expect(connection.transaction_open?).to be(false)

        expect(described_class.add_impression_seconds(id: 0, user_id: nil)).to eq(0)
        expect(connection.select_value("SHOW synchronous_commit")).to eq("on")
      end
    end
  end
end
