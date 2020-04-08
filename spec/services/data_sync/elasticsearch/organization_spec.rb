require "rails_helper"

RSpec.describe DataSync::Elasticsearch::Organization, type: :service do
  let!(:organization) { create(:organization) }

  describe "#call" do
    it "reindexes RELATED_DOCS when sync is needed " do
      syncer = described_class.new(organization, name: %w[name1 name2])
      described_class::RELATED_DOCS.each do |method_name|
        allow(syncer).to receive(method_name).and_call_original
      end
      syncer.call
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).to have_received(method_name)
      end
    end

    it "does not reindex when sync is not needed" do
      syncer = described_class.new(organization, articles_count: [0, 1])
      described_class::RELATED_DOCS.each { |method_name| allow(syncer).to receive(method_name) }
      syncer.call
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).not_to have_received(method_name)
      end
    end
  end
end
