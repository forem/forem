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

    it "generates proper div with content" do
      rendered = generate_runkit_liquid(preamble, content).render

      # rubocop:disable Style/StringLiterals
      expect(rendered).to include('<code')
      expect(rendered).to include('style="display: none"')
      expect(rendered).to include('await getJSON(&quot;https://storage.googleapis.com/maps-devrel/google.json&quot;);')
      # rubocop:enable Style/StringLiterals
    end
  end
end
