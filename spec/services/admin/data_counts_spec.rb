require "rails_helper"

RSpec.describe Admin::DataCounts, type: :service do
  it "returns proper data type" do
    expect(described_class.call).to be_an_instance_of(described_class::Response)
  end

  it "returns an integer" do
    expect(described_class.call.open_abuse_reports_count).to eq(0)
  end
end
