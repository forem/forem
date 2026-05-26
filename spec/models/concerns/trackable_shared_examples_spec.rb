require "rails_helper"

# rubocop:disable RSpec/DescribeClass
# This spec exercises the shared example, not a single class — the meta-class is
# created at runtime via stub_const, so a string description is required.
RSpec.describe "trackable shared examples" do
  # Temp table — schema operations are not transactional; recreating per example
  # would be wasteful and isn't the unit under test.
  # rubocop:disable RSpec/BeforeAfterAll
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
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    stub_const("TrackableMetaRecord", Class.new(ApplicationRecord) do
      self.table_name = "trackable_meta_records"
      include Trackable
      def self.name = "TrackableMetaRecord"
      def trackable_user_ids = user_id
    end)
  end

  describe "TrackableMetaRecord" do
    subject { TrackableMetaRecord.new(title: "starter", user_id: 1) }

    it_behaves_like "trackable"
  end
end
# rubocop:enable RSpec/DescribeClass
