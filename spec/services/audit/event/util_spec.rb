require "rails_helper"

RSpec.describe Audit::Event::Util, type: :service do
  let(:utils) { described_class }
  let!(:event) { build(:activesupport_event) }

  describe "Serialization" do
    it "evaluates to same object" do
      event_dup = event.dup
      compare_to = utils.deserialize(utils.serialize(event))

      expect(event_dup.time.iso8601.in_time_zone).to eq(compare_to[:time].iso8601)
      expect(event_dup.end.iso8601.in_time_zone).to eq(compare_to[:end].iso8601)
    end
  end
end
