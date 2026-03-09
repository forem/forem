require "rails_helper"

RSpec.describe Ai::OrgPageCrawler do
  let(:organization) { create(:organization, name: "TestOrg") }
  let(:urls) { ["https://www.testorg.com"] }
  let(:service) { described_class.new(organization: organization, urls: urls) }

  let(:ai_extraction_response) do
    <<~RESPONSE
      TAGLINE: Build great things with TestOrg
      DESCRIPTION: TestOrg is a platform that helps developers build, deploy, and scale applications.
      BRAND_COLOR: #FF5733
      FEATURES: [{"title": "Fast APIs", "description": "Lightning fast API endpoints"}, {"title": "Easy SDKs", "description": "SDKs for every language"}]
    RESPONSE
  end

  before do
    allow(HTTParty).to receive(:get).and_return(
      double(body: "<html><body><h1>TestOrg</h1><p>Build great things</p></body></html>", success?: true)
    )
    allow(Ai::Base).to receive(:new).and_return(double(call: ai_extraction_response))
    allow(Rails.cache).to receive(:fetch).and_call_original
  end

  describe "#crawl" do
    it "returns AI-extracted tagline" do
      result = service.crawl
      expect(result[:title]).to eq("Build great things with TestOrg")
    end

    it "returns AI-extracted description" do
      result = service.crawl
      expect(result[:description]).to include("platform that helps developers")
    end

    it "returns AI-detected brand color" do
      result = service.crawl
      expect(result[:detected_color]).to eq("#FF5733")
    end

    it "returns AI-extracted features" do
      result = service.crawl
      expect(result[:features]).to be_an(Array)
      expect(result[:features].length).to eq(2)
      expect(result[:features].first["title"]).to eq("Fast APIs")
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

    context "when AI extraction fails" do
      before do
        allow(Ai::Base).to receive(:new).and_raise(StandardError, "API Error")
      end

      it "falls back to MetaInspector parsing" do
        mock_page = double("MetaInspector",
                           best_title: "TestOrg Fallback",
                           description: "Fallback description",
                           images: double(best: "https://testorg.com/og.png"),
                           meta_tags: { "name" => { "theme-color" => ["#123456"] } })
        allow(MetaInspector).to receive(:new).and_return(mock_page)

        result = service.crawl
        expect(result[:title]).to eq("TestOrg Fallback")
        expect(result[:description]).to eq("Fallback description")
      end
    end

    context "when URL is unreachable" do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, "Connection refused")
      end

      it "returns error with graceful fallback" do
        result = service.crawl
        expect(result[:error]).to be_present
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
