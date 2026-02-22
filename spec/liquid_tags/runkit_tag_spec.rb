require "rails_helper"

RSpec.describe RunkitTag, type: :liquid_tag do
  describe "#render" do
    let(:preamble) do
      <<~CODE
        const myVar = 9001
      CODE
    end

    let(:content) do
      <<~CODE
        // GeoJSON!
        var getJSON = require("async-get-json");

        await getJSON("https://storage.googleapis.com/maps-devrel/google.json");
      CODE
    end

    let(:content_with_html) do
      <<~CODE
        const { ValueViewerSymbol } = require("@runkit/value-viewer");

        const myCustomObject = {
            [ValueViewerSymbol]: {
                title: "My First Viewer",
                HTML: "<marquee>🍔Hello, World!🍔</marquee>"
            }
        };
      CODE
    end

    def generate_runkit_liquid(preamble_str, block)
      Liquid::Template.register_tag("runkit", described_class)
      Liquid::Template.parse("{% runkit #{preamble_str}%}#{block}{% endrunkit %}")
    end

    it "generates proper div with content" do
      rendered = generate_runkit_liquid(preamble, content).render

      # rubocop:disable Style/StringLiterals
      expect(rendered).to include('<code')
      expect(rendered).to include('style="display: none"')
      expect(rendered).to include('await getJSON(&quot;https://storage.googleapis.com/maps-devrel/google.json&quot;);')
      # rubocop:enable Style/StringLiterals
    end

    it "preserves HTML tags in content" do
      rendered = generate_runkit_liquid(preamble, content_with_html).render

      # Check that the HTML tags are preserved
      expect(rendered).to include('&lt;marquee&gt;🍔Hello, World!🍔&lt;/marquee&gt;')
      expect(rendered).not_to include('🍔Hello, World!🍔') # This would indicate HTML was stripped
    end
  end
end
