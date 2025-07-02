require "rails_helper"

RSpec.describe Ahoy::Visit do
  let(:visit) { create(:ahoy_visit) }

  describe "validations" do
    describe "builtin validations" do
      subject { visit }

      it { is_expected.to have_many(:events).class_name("Ahoy::Event").dependent(:destroy) }
      it { is_expected.to belong_to(:user).optional }
    end

    describe "#fast_destroy_old_notifications" do
      it "bulk deletes visits older than given timestamp" do
        allow(BulkSqlDelete).to receive(:delete_in_batches)
        described_class.fast_destroy_old_visits("a_time")
        expect(BulkSqlDelete).to have_received(:delete_in_batches).with(a_string_including("< 'a_time'"))
      end
    end
  end
end
