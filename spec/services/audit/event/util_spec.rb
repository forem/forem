require "rails_helper"

RSpec.describe Audit::Event::Util, type: :service do
  let(:utils) { described_class }
  let!(:event) { build(:activesupport_event) }

  describe "Serialization" do
    it "evaluates to same object" do
      compare_to = utils.deserialize(utils.serialize(event))

      expect(event.class).to eq(compare_to.class)
      expect(event.time.iso8601.in_time_zone).to eq(compare_to.time.iso8601)
      expect(event.end.iso8601.in_time_zone).to eq(compare_to.end.iso8601)
    end
  end
end
