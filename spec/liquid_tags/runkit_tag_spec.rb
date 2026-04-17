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

    def generate_runkit_liquid(preamble_str, block)
      Liquid::Template.register_tag("runkit", described_class)
      Liquid::Template.parse("{% runkit #{preamble_str}%}#{block}{% endrunkit %}")
    end

    it "generates a fallback block with the original source" do
      rendered = generate_runkit_liquid(preamble, content).render

      expect(rendered).to include('RunKit is no longer available')
      expect(rendered).to include('<pre class="ltag-runkit-fallback__code"><code>')
      expect(rendered).to include('await getJSON(&quot;https://storage.googleapis.com/maps-devrel/google.json&quot;);')
    end
  end
end
