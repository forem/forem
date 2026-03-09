require "rails_helper"

RSpec.describe Ai::OrgPageCrawler do
  let(:organization) { create(:organization, name: "TestOrg") }
  let(:urls) { ["https://www.testorg.com"] }
  let(:service) { described_class.new(organization: organization, urls: urls) }

  let(:mock_page) do
    double("MetaInspector",
           best_title: "TestOrg - Build Great Things",
           description: "A platform for building great things",
           best_url: "https://www.testorg.com",
           images: double(best: "https://www.testorg.com/og.png"),
           meta: {},
           meta_tags: { "name" => { "theme-color" => ["#FF5733"] } })
  end

  before do
    allow(HTTParty).to receive(:get).and_return(double(body: "<html></html>", success?: true))
    allow(MetaInspector).to receive(:new).and_return(mock_page)
    allow(Rails.cache).to receive(:fetch).and_call_original
  end

  describe "#crawl" do
    it "returns structured crawl data" do
      result = service.crawl
      expect(result[:title]).to eq("TestOrg - Build Great Things")
      expect(result[:description]).to eq("A platform for building great things")
      expect(result[:og_image]).to eq("https://www.testorg.com/og.png")
    end

    it "detects brand color from meta theme-color" do
      result = service.crawl
      expect(result[:detected_color]).to eq("#FF5733")
    end

    it "returns dev_posts as an array" do
      result = service.crawl
      expect(result[:dev_posts]).to be_an(Array)
    end

    it "builds links from provided URLs" do
      result = service.crawl
      expect(result[:links]).to include(hash_including(url: "https://www.testorg.com", label: "Website"))
    end

    context "with multiple URLs" do
      let(:urls) { ["https://www.testorg.com", "https://docs.testorg.com/getting-started"] }

      it "includes all provided links" do
        result = service.crawl
        expect(result[:links].length).to eq(2)
      end
    end

    context "when URL is unreachable" do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, "Connection refused")
      end

      it "returns nil metadata with graceful fallback" do
        result = service.crawl
        expect(result[:title]).to be_nil
        expect(result[:description]).to be_nil
        expect(result[:dev_posts]).to be_an(Array)
      end
    end

    context "when crawl raises an unexpected error" do
      before do
        allow(service).to receive(:crawl_primary_url).and_raise(StandardError, "Unexpected failure")
      end

      it "returns error hash with safe dev_posts fallback" do
        result = service.crawl
        expect(result[:error]).to eq("Unexpected failure")
        expect(result[:title]).to be_nil
        expect(result[:dev_posts]).to be_an(Array)
      end
    end

    context "when org has published articles" do
      before do
        create(:article, organization: organization, title: "TestOrg Tutorial", published: true, positive_reactions_count: 10)
      end

      it "includes org articles in dev_posts" do
        result = service.crawl
        expect(result[:dev_posts].any? { |p| p[:title] == "TestOrg Tutorial" }).to be true
      end
    end

    it "limits to 4 URLs maximum" do
      many_urls = (1..6).map { |i| "https://test#{i}.com" }
      svc = described_class.new(organization: organization, urls: many_urls)
      result = svc.crawl
      expect(result[:links].length).to eq(4)
    end
  end
end
