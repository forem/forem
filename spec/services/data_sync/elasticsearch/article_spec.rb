require "rails_helper"

RSpec.describe DataSync::Elasticsearch::Article, type: :service do
  it "defines necessary constants" do
    expect(described_class::RELATED_DOCS).not_to be_nil
    expect(described_class::SHARED_FIELDS).not_to be_nil
  end
end
