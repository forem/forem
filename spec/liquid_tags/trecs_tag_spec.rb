require "rails_helper"

RSpec.describe TrecsTag, type: :liquid_tag do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:parse_context) { { source: article, user: user } }
  let(:id) { "9f66b056-dee1-460b-a2a0-fb45df6461d2" }
  let(:watch_url) { "https://trecs.run/watch/#{id}" }

  def generate_tag(input)
    Liquid::Template.register_tag("trecs", TrecsTag)
    Liquid::Template.parse("{% trecs #{input} %}", parse_context)
  end

  def generate_embed(url)
    UnifiedEmbed.register(described_class, regexp: described_class::REGISTRY_REGEXP)
    Liquid::Template.parse("{% embed #{url} %}", parse_context)
  end

  describe "input" do
    it "accepts a watch URL" do
      expect { generate_tag(watch_url) }.not_to raise_error
    end

    it "accepts a bare recording id" do
      expect { generate_tag(id) }.not_to raise_error
    end

    it "accepts an uppercase recording id" do
      expect { generate_tag(id.upcase) }.not_to raise_error
    end

    it "accepts a watch URL with a start time" do
      expect { generate_tag("#{watch_url}?t=35") }.not_to raise_error
    end

    it "rejects ids that are not UUIDs", :aggregate_failures do
      expect { generate_tag("inv@lid") }.to raise_error(StandardError, /Invalid trecs recording ID/)
      expect { generate_tag("1234") }.to raise_error(StandardError)
      expect { generate_tag("#{id}extra") }.to raise_error(StandardError)
    end

    it "rejects URLs on other hosts" do
      expect { generate_tag("https://example.com/watch/#{id}") }.to raise_error(StandardError)
    end
  end

  describe "rendering" do
    it "renders an iframe pointing at the trecs embed page", :aggregate_failures do
      embed = generate_tag(watch_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"https://trecs.run/embed/#{id}\"")
    end

    it "passes the start time on to the embed page" do
      embed = generate_tag("#{watch_url}?t=35").render

      expect(embed).to include("src=\"https://trecs.run/embed/#{id}?t=35\"")
    end

    it "renders when used through the embed tag" do
      stub_network_request(url: watch_url)
      embed = generate_embed(watch_url).render

      expect(embed).to include("src=\"https://trecs.run/embed/#{id}\"")
    end
  end

  describe "editor documentation" do
    %w[editor_liquid_help supported_url_embeds_list].product(%w[en fr pt]).each do |partial, locale|
      it "lists trecs in pages/_#{partial}.#{locale}" do
        help = Rails.root.join("app/views/pages/_#{partial}.#{locale}.html.erb").read

        expect(help).to include('<li class="ml-4">trecs</li>')
      end
    end
  end
end
