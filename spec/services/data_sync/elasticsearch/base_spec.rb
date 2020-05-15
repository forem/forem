require "rails_helper"

RSpec.describe DataSync::Elasticsearch::Base, type: :service do
  let!(:updated_record) { instance_double("Record", saved_changes: { name: %w[name1 name2] }) }
  let(:syncer) { described_class.new(updated_record) }

  describe "#call" do
    before do
      stub_const("#{described_class}::SHARED_FIELDS", %i[name])
      allow(syncer).to receive(:sync_related_documents)
    end

    it "syncs related_documents when sync is needed " do
      syncer.call
      expect(syncer).to have_received(:sync_related_documents)
    end

    it "does not sync related_documents when sync is not needed" do
      allow(updated_record).to receive(:saved_changes).and_return(twitter_url: %w[url1 url2])
      syncer.call
      expect(syncer).not_to have_received(:sync_related_documents)
    end
  end
end
