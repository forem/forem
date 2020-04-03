require "rails_helper"

RSpec.describe DataSync::Elasticsearch::User, type: :service do
  let!(:user) { create(:user) }

  describe "#sync_documents" do
    it "reindexes RELATED_DOCS when sync is needed " do
      syncer = described_class.new(user, username: %w[name1 name2])
      described_class::RELATED_DOCS.each do |method_name|
        allow(syncer).to receive(method_name).and_call_original
      end
      syncer.sync_documents
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).to have_received(method_name)
      end
    end

    it "does not reindex when sync is not needed" do
      syncer = described_class.new(user, stackoverflow_url: [nil, "url"])
      described_class::RELATED_DOCS.each { |method_name| allow(syncer).to receive(method_name) }
      syncer.sync_documents
      described_class::RELATED_DOCS.each do |method_name|
        expect(syncer).not_to have_received(method_name)
      end
    end
  end
end
