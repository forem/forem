require "rails_helper"

RSpec.describe CloudRunTag, type: :liquid_tag do
  let(:valid_url)   { "https://hello-world-app-584800428475.us-west1.run.app/" }
  let(:simple_url)  { "https://service-abc123.run.app" }
  let(:no_slash)    { "https://my-app-12ab34cd5e-australia-southeast1.run.app" }
  let(:region_url)  { "https://hello-world-app-584800428475.us-west1.run.app" }
  let(:invalid_url) { "https://example.com/invalid" }
  let(:bad_format)  { "not-a-url" }
  let(:not_run_app) { "https://My-App-123.example.com" }

  def parse_liquid(input)
    Liquid::Template.register_tag("cloudrun", CloudRunTag)
    Liquid::Template.parse("{% cloudrun #{input} %}")
  end

  # ---------------------------------------------------------------------------
  # URL validation (unchanged from original)
  # ---------------------------------------------------------------------------
  describe "URL validation" do
    it "accepts valid URL with trailing slash" do
      rendered = parse_liquid(valid_url).render
      expect(rendered).to include('class="ltag__cloud-run"')
      expect(rendered).to include("<iframe")
      expect(rendered).to include("src=\"#{valid_url.strip}\"")
    end

    it "accepts valid URL without trailing slash" do
      rendered = parse_liquid(no_slash).render
      expect(rendered).to include("src=\"#{no_slash}\"")
    end

    it "accepts URL with region in hostname" do
      rendered = parse_liquid(region_url).render
      expect(rendered).to include("src=\"#{region_url}\"")
    end

    it "accepts simple Cloud Run URL format" do
      rendered = parse_liquid(simple_url).render
      expect(rendered).to include("src=\"#{simple_url}\"")
    end

    it "raises an error for invalid URL" do
      expect { parse_liquid(invalid_url).render }.to raise_error("Invalid Cloud Run URL")
    end

    it "raises an error for non-URL input" do
      expect { parse_liquid(bad_format).render }.to raise_error("Invalid Cloud Run URL")
    end

    it "raises an error for non-.run.app domain" do
      expect { parse_liquid(not_run_app).render }.to raise_error("Invalid Cloud Run URL")
    end
  end

  # ---------------------------------------------------------------------------
  # Legacy ratio presets (backwards compat)
  # ---------------------------------------------------------------------------
  describe "legacy ratio presets" do
    it "renders default height (600px) when no ratio given" do
      expect(parse_liquid(valid_url).render).to include("height: 600px")
    end

    it "renders landscape preset at 400px" do
      expect(parse_liquid("#{valid_url} landscape").render).to include("height: 400px")
    end

    it "renders portrait preset at 900px" do
      expect(parse_liquid("#{valid_url} portrait").render).to include("height: 900px")
    end

    it "renders default height for unknown ratio keyword" do
      expect(parse_liquid("#{valid_url} widescreen").render).to include("height: 600px")
    end
  end

  # ---------------------------------------------------------------------------
  # Explicit height= parameter
  # ---------------------------------------------------------------------------
  describe "explicit height= parameter" do
    it "renders at specified height" do
      expect(parse_liquid("#{valid_url} height=720").render).to include("height: 720px")
    end

    it "overrides legacy ratio when both given" do
      # height= wins over landscape
      expect(parse_liquid("#{valid_url} landscape height=800").render).to include("height: 800px")
    end

    it "clamps height below minimum (200px)" do
      expect(parse_liquid("#{valid_url} height=50").render).to include("height: 200px")
    end

    it "clamps height above maximum (2000px)" do
      expect(parse_liquid("#{valid_url} height=9999").render).to include("height: 2000px")
    end
  end

  # ---------------------------------------------------------------------------
  # Explicit width= parameter
  # ---------------------------------------------------------------------------
  describe "explicit width= parameter" do
    it "renders wrapper at specified width%" do
      rendered = parse_liquid("#{valid_url} width=80").render
      expect(rendered).to include("width: 80%;")
    end

    it "defaults to 100% when no width given" do
      rendered = parse_liquid(valid_url).render
      expect(rendered).to include("width: 100%;")
    end

    it "clamps width below minimum (10%)" do
      rendered = parse_liquid("#{valid_url} width=2").render
      expect(rendered).to include("width: 10%;")
    end

    it "clamps width above maximum (100%)" do
      rendered = parse_liquid("#{valid_url} width=999").render
      expect(rendered).to include("width: 100%;")
    end
  end

  # ---------------------------------------------------------------------------
  # Scaling — scale:fit / scale:stretch + native:WxH
  # ---------------------------------------------------------------------------
  describe "fit-to-frame scaling" do
    let(:full_input) { "#{valid_url} height=600 width=100 scale:fit native:1920x1080" }

    it "emits data-native-w and data-native-h attributes" do
      rendered = parse_liquid(full_input).render
      expect(rendered).to include('data-native-w="1920"')
      expect(rendered).to include('data-native-h="1080"')
    end

    it "emits data-scale-mode for scale:fit" do
      rendered = parse_liquid(full_input).render
      expect(rendered).to include('data-scale-mode="fit"')
    end

    it "emits data-scale-mode for scale:stretch" do
      rendered = parse_liquid("#{valid_url} height=600 scale:stretch native:1280x720").render
      expect(rendered).to include('data-scale-mode="stretch"')
    end

    it "injects the scaling <script> block" do
      rendered = parse_liquid(full_input).render
      expect(rendered).to include("<script>")
      expect(rendered).to include("applyScale")
    end

    it "does NOT inject scaling when native: is missing" do
      rendered = parse_liquid("#{valid_url} height=600 scale:fit").render
      expect(rendered).not_to include("data-scale-mode")
      expect(rendered).not_to include("<script>")
    end

    it "does NOT inject scaling when scale: is missing" do
      rendered = parse_liquid("#{valid_url} height=600 native:1920x1080").render
      expect(rendered).not_to include("data-scale-mode")
      expect(rendered).not_to include("<script>")
    end

    it "ignores invalid native: format gracefully" do
      rendered = parse_liquid("#{valid_url} height=600 scale:fit native:badformat").render
      expect(rendered).not_to include("data-scale-mode")
    end

    it "ignores unknown scale: mode gracefully" do
      rendered = parse_liquid("#{valid_url} height=600 scale:zoom native:1920x1080").render
      expect(rendered).not_to include("data-scale-mode")
    end
  end

  # ---------------------------------------------------------------------------
  # embed tag integration (CloudRunTag via UnifiedEmbed)
  # ---------------------------------------------------------------------------
  describe "embed tag integration" do
    def parse_embed(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "routes via embed tag correctly" do
      rendered = parse_embed(region_url).render
      expect(rendered).to include('class="ltag__cloud-run"')
      expect(rendered).to include("<iframe")
      expect(rendered).to include("src=\"#{region_url}\"")
    end
  end
end
