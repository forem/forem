require "rails_helper"

RSpec.describe Trackable do
  # We define a temporary AR-backed table so we can include the concern
  # without coupling the spec to any production model.
  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :trackable_test_records, force: true do |t|
          t.string  :name
          t.integer :user_id
          t.datetime :engaged_at
          t.timestamps
        end
      end
    end
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.drop_table :trackable_test_records
    end
  end

  let(:trackable_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "trackable_test_records"
      include Trackable

      def self.name
        "TrackableTestRecord"
      end

      def trackable_user_ids
        user_id
      end
    end
  end

  describe "#trackable_user_ids" do
    it "raises NotImplementedError when not defined by the including class" do
      anon_class = Class.new(ApplicationRecord) do
        self.table_name = "trackable_test_records"
        include Trackable
        def self.name; "Anon"; end
      end

      record = anon_class.new
      expect { record.trackable_user_ids }.to raise_error(NotImplementedError)
    end
  end

  describe "#trackable_payload" do
    it "returns as_json minus DEFAULT_EXCLUDED_KEYS" do
      record = trackable_class.new(name: "alpha", user_id: 7)
      payload = record.trackable_payload

      expect(payload).to include("name" => "alpha", "user_id" => 7)
      expect(payload.keys).not_to include("created_at", "updated_at")
    end

    it "is overridable per model" do
      overridden = Class.new(trackable_class) do
        def self.name; "Overridden"; end
        def trackable_payload; { only: name }; end
      end

      expect(overridden.new(name: "n").trackable_payload).to eq(only: "n")
    end
  end

  describe "lifecycle callbacks" do
    before do
      stub_adapter = instance_double(Trackers::Base, enabled?: true)
      allow(stub_adapter).to receive(:track)
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    it "enqueues a model_created event after create" do
      trackable_class.create!(name: "alpha", user_id: 7)

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_created",
        [7],
        hash_including("name" => "alpha", "user_id" => 7),
        kind_of(String),
      )
    end

    it "enqueues a model_updated event after update" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      record.update!(name: "beta")

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_updated",
        [7],
        hash_including("name" => "beta"),
        kind_of(String),
      )
    end

    it "enqueues a model_destroyed event after destroy with the snapshotted user ids" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      record.destroy!

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_destroyed",
        [7],
        kind_of(Hash),
        kind_of(String),
      )
    end

    it "does not enqueue when transaction is rolled back" do
      trackable_class.transaction do
        trackable_class.create!(name: "alpha", user_id: 7)
        raise ActiveRecord::Rollback
      end

      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end
  end
end
