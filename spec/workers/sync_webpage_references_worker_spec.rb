require "rails_helper"

RSpec.describe SyncWebpageReferencesWorker do
  describe "#perform" do
    let(:article) { create(:article, body_markdown: "---\ntitle: My article\n---\n\nA link to https://example.com/page") }

    before do
      allow(WebpageExtractor).to receive(:extract).and_return(["https://example.com/page", "https://test.com/other"])
      allow(LinkedDomains::UpdateScoreWorker).to receive(:perform_async)
    end

    it "creates domains and references for extracted URLs" do
      expect {
        subject.perform("Article", article.id)
      }.to change(LinkedDomain, :count).by(2)
       .and change(WebpageReference, :count).by(2)

      expect(LinkedDomain.pluck(:host)).to include("example.com", "test.com")
    end

    it "clears old references before inserting new ones" do
      # Setup old reference
      domain = LinkedDomain.create!(host: "old.com")
      WebpageReference.create!(record: article, linked_domain: domain, url: "https://old.com/page")

      expect {
        subject.perform("Article", article.id)
      }.to change(WebpageReference, :count).from(1).to(2)

      expect(article.webpage_references.pluck(:url)).not_to include("https://old.com/page")
    end

    it "triggers LinkedDomains::UpdateScoreWorker for old and new domains" do
      domain_old = LinkedDomain.create!(host: "old.com")
      WebpageReference.create!(record: article, linked_domain: domain_old, url: "https://old.com/page")

      subject.perform("Article", article.id)

      domain_new1 = LinkedDomain.find_by(host: "example.com")
      domain_new2 = LinkedDomain.find_by(host: "test.com")

      expect(LinkedDomains::UpdateScoreWorker).to have_received(:perform_async).with(domain_old.id)
      expect(LinkedDomains::UpdateScoreWorker).to have_received(:perform_async).with(domain_new1.id)
      expect(LinkedDomains::UpdateScoreWorker).to have_received(:perform_async).with(domain_new2.id)
    end

    it "does nothing if the record does not exist" do
      expect {
        subject.perform("Article", -1)
      }.not_to change(WebpageReference, :count)
    end
  end
end
