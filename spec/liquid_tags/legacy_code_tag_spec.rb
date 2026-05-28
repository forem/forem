require "rails_helper"

RSpec.describe LegacyCodeTag, type: :liquid_tag do
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

    def generate_legacy_code_liquid(preamble_str, block)
      Liquid::Template.register_tag("runkit", described_class)
      Liquid::Template.parse("{% runkit #{preamble_str}%}#{block}{% endrunkit %}")
    end

    it "generates a fallback block with the original source" do
      rendered = generate_legacy_code_liquid(preamble, content).render

      expect(rendered).to include('This code block is no longer available')
      expect(rendered).to include('<pre class="ltag-legacy-code-fallback__code"><code>')
      expect(rendered).to include('await getJSON(&quot;https://storage.googleapis.com/maps-devrel/google.json&quot;);')
    end
  end
end
