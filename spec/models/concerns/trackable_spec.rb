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
end
