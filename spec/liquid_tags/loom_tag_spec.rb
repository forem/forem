require "rails_helper"

RSpec.describe LoomTag do
  subject(:loom_tag) { described_class }

  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:parse_context) { { source: article, user: user } }
  let(:loom_share_url) { "https://loom.com/share/12fb674d39dd4fe281becee7cdbc3cd1" }
  let(:loom_embed_url) { "https://loom.com/embed/12fb674d39dd4fe281becee7cdbc3cd1" }
  let(:www_loom_url) { "https://www.loom.com/share/12fb674d39dd4fe281becee7cdbc3cd1" }
  let(:loom_url_with_query) do
    "https://loom.com/share/12fb674d39dd4fe281becee7cdbc3cd1?sharedAppSource=personal_library"
  end
  let(:expected_link) { "https://loom.com/embed/12fb674d39dd4fe281becee7cdbc3cd1" }

  let(:invalid_loom_urls) do
    [
      "https://loom.com/embed/should_have_no_underscores",
      "https://loom.com/embed/should-have-no-dashes",
    ]
  end

  let(:registry_regexp) do
    %r{https://(?:www\.)?loom\.com/(?:share|embed)/(?<video_id>[a-zA-Z0-9]+)(?:\?[\w=-]+)?$}
  end

  def generate_embed(url)
    UnifiedEmbed.register(described_class, regexp: registry_regexp)
    Liquid::Template.parse("{% embed #{url} %}")
  end

  describe "rendering" do
    it "returns StandardError for invalid Loom URL", :aggregate_failures do
      invalid_loom_urls.each do |invalid_url|
        expect do
          generate_embed(invalid_url)
        end.to raise_error(StandardError, "Embed URL not valid")
      end
    end

    it "returns Loom embed for valid Loom share URL" do
      embed = generate_embed(loom_share_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Loom embed for valid Loom embed URL" do
      embed = generate_embed(loom_embed_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Loom embed for valid Loom www URL" do
      embed = generate_embed(www_loom_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end

    it "returns Loom embed for valid Loom URL with query paramaters" do
      embed = generate_embed(loom_url_with_query).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"#{expected_link}\"")
    end
  end
end
