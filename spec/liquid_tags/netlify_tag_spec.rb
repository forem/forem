require "rails_helper"

RSpec.describe NetlifyTag, type: :liquid_tag do
  let(:user) { create(:user) }

  def generate_tag(url)
    Liquid::Template.register_tag("netlify", described_class)
    Liquid::Template.parse("{% netlify #{url} %}", source: Article.new, user: user)
  end

  describe "valid URLs" do
    it "renders an iframe for a basic netlify.app URL" do
      result = generate_tag("https://cld-api-x.netlify.app/iframe.html").render
      expect(result).to include("<iframe")
      expect(result).to include('src="https://cld-api-x.netlify.app/iframe.html"')
    end

    it "renders an iframe for a URL with query params" do
      url = "https://cld-api-x.netlify.app/iframe.html?args=&id=experiences-api-explorer--default-use-cases&viewMode=story"
      result = generate_tag(url).render
      expect(result).to include("<iframe")
      expect(result).to include("cld-api-x.netlify.app")
    end

    it "renders an iframe for a root netlify.app URL" do
      result = generate_tag("https://my-app.netlify.app").render
      expect(result).to include("<iframe")
      expect(result).to include('src="https://my-app.netlify.app"')
    end

    it "renders an iframe for a URL with a path" do
      result = generate_tag("https://my-app.netlify.app/some/path").render
      expect(result).to include('src="https://my-app.netlify.app/some/path"')
    end

    it "does not add sandbox attribute" do
      result = generate_tag("https://my-app.netlify.app").render
      expect(result).not_to include("sandbox=")
    end
  end

  describe "invalid URLs" do
    it "raises error for non-netlify URL" do
      expect do
        generate_tag("https://example.com")
      end.to raise_error(StandardError, /Invalid Netlify URL/)
    end

    it "raises error for HTTP URL" do
      expect do
        generate_tag("http://my-app.netlify.app")
      end.to raise_error(StandardError, /Invalid Netlify URL/)
    end

    it "raises error for empty input" do
      expect do
        generate_tag("")
      end.to raise_error(StandardError, /Invalid Netlify URL/)
    end
  end
end
