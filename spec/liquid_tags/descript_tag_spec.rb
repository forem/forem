require "rails_helper"

RSpec.describe DescriptTag, type: :liquid_tag do
  subject(:descript_tag) { described_class }

  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:parse_context) { { source: article, user: user } }
  let(:descript_url) { "https://share.descript.com/view/PnCDOfxkfnP" }
  let(:www_descript_url) { "https://www.share.descript.com/view/PnCDOfxkfnP" }
  let(:http_descript_url) { "http://share.descript.com/view/PnCDOfxkfnP" }
  let(:descript_url_with_query) { "https://share.descript.com/view/PnCDOfxkfnP?utm_source=share" }
  let(:descript_url_with_trailing_slash) { "https://share.descript.com/view/PnCDOfxkfnP/" }
  let(:expected_link) { "https://share.descript.com/view/PnCDOfxkfnP" }

  let(:invalid_descript_urls) do
    [
      "https://descript.com/view/PnCDOfxkfnP",
      "https://share.descript.com/watch/PnCDOfxkfnP",
    ]
  end

  def generate_embed(url)
    UnifiedEmbed.register(described_class, regexp: described_class::REGISTRY_REGEXP)
    Liquid::Template.parse("{% embed #{url} %}")
  end

  describe "rendering" do
    it "returns StandardError for invalid Descript URL", :aggregate_failures do
      invalid_descript_urls.each do |invalid_url|
        stub_network_request(url: invalid_url, status_code: 404)
        expect do
          generate_embed(invalid_url)
        end.to raise_error(StandardError, "URL provided was not found; please check and try again")
      end
    end

    it "returns Descript embed for valid https URL" do
      stub_network_request(url: descript_url)
      embed = generate_embed(descript_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Descript embed for valid www URL" do
      stub_network_request(url: www_descript_url)
      embed = generate_embed(www_descript_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Descript embed for valid http URL" do
      stub_network_request(url: http_descript_url)
      embed = generate_embed(http_descript_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Descript embed for valid URL with query parameters" do
      stub_network_request(url: descript_url_with_query)
      embed = generate_embed(descript_url_with_query).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Descript embed for valid URL with trailing slash" do
      stub_network_request(url: descript_url_with_trailing_slash)
      embed = generate_embed(descript_url_with_trailing_slash).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end
  end
end
