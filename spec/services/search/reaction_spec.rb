require "rails_helper"

RSpec.describe Search::Reaction, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end
end
