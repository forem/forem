require "rails_helper"

RSpec.describe "trackable shared examples" do
  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :trackable_meta_records, force: true do |t|
          t.string :title
          t.integer :user_id
          t.timestamps
        end
      end
    end
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.drop_table :trackable_meta_records
    end
  end

  before do
    stub_const("TrackableMetaRecord", Class.new(ApplicationRecord) do
      self.table_name = "trackable_meta_records"
      include Trackable
      def self.name; "TrackableMetaRecord"; end
      def trackable_user_ids; user_id; end
    end)
  end

  describe "TrackableMetaRecord" do
    subject { TrackableMetaRecord.new(title: "starter", user_id: 1) }

    it_behaves_like "trackable"
  end
end
