require "rails_helper"

RSpec.describe CloudRunTag, type: :liquid_tag do
  describe "#url" do
    let(:valid_cloud_run_url) { "https://hello-world-app-584800428475.us-west1.run.app/" }
    let(:valid_cloud_run_url_no_slash) { "https://my-app-12ab34cd5e-australia-southeast1.run.app" }
    let(:valid_cloud_run_simple) { "https://service-abc123.run.app" }
    let(:valid_cloud_run_with_region) { "https://hello-world-app-584800428475.us-west1.run.app" }
    let(:invalid_cloud_run_url) { "https://example.com/invalid" }
    let(:invalid_format_url) { "not-a-url" }
    let(:invalid_non_run_app_url) { "https://My-App-123.example.com" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("cloudrun", CloudRunTag)
      Liquid::Template.parse("{% cloudrun #{url} %}")
    end

    it "accepts valid Cloud Run URL with trailing slash" do
      liquid = generate_new_liquid(valid_cloud_run_url)
      expect(liquid.render).to include('<div class="ltag__cloud-run">')
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include('src="https://hello-world-app-584800428475.us-west1.run.app/"')
    end

    it "accepts valid Cloud Run URL without trailing slash" do
      liquid = generate_new_liquid(valid_cloud_run_url_no_slash)
      expect(liquid.render).to include('<div class="ltag__cloud-run">')
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include('src="https://my-app-12ab34cd5e-australia-southeast1.run.app"')
    end

    it "accepts valid Cloud Run URL with region in hostname" do
      liquid = generate_new_liquid(valid_cloud_run_with_region)
      expect(liquid.render).to include('<div class="ltag__cloud-run">')
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include('src="https://hello-world-app-584800428475.us-west1.run.app"')
    end

    it "accepts simple Cloud Run URL format" do
      liquid = generate_new_liquid(valid_cloud_run_simple)
      expect(liquid.render).to include('<div class="ltag__cloud-run">')
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include('src="https://service-abc123.run.app"')
    end

    it "renders iframe with proper attributes" do
      liquid = generate_new_liquid(valid_cloud_run_url)
      rendered = liquid.render
      
      expect(rendered).to include('frameborder="0"')
      expect(rendered).to include('height="600px"')
      expect(rendered).to include('loading="lazy"')
      expect(rendered).to include('style="width: 100%; border: 1px solid #e1e5e9; border-radius: 4px;"')
    end

    it "raises an error for invalid Cloud Run URL" do
      expect { generate_new_liquid(invalid_cloud_run_url).render }.to raise_error("Invalid Cloud Run URL")
    end

    it "raises an error for invalid format" do
      expect { generate_new_liquid(invalid_format_url).render }.to raise_error("Invalid Cloud Run URL")
    end

    it "raises an error for non-Cloud Run URLs" do
      expect { generate_new_liquid(invalid_non_run_app_url).render }.to raise_error("Invalid Cloud Run URL")
    end
  end

  describe "embed tag integration" do
    let(:valid_cloud_run_url) { "https://hello-world-app-584800428475.us-west1.run.app" }

    def generate_embed_liquid(url)
      # Stub the HTTP request for URL validation
      stub_request(:head, url)
        .to_return(status: 200, body: "", headers: {})
      
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(valid_cloud_run_url)
      expect(liquid.render).to include('<div class="ltag__cloud-run">')
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include('src="https://hello-world-app-584800428475.us-west1.run.app"')
    end

    it "renders iframe with proper attributes via embed tag" do
      liquid = generate_embed_liquid(valid_cloud_run_url)
      rendered = liquid.render
      
      expect(rendered).to include('frameborder="0"')
      expect(rendered).to include('height="600px"')
      expect(rendered).to include('loading="lazy"')
      expect(rendered).to include('style="width: 100%; border: 1px solid #e1e5e9; border-radius: 4px;"')
    end
  end
end
