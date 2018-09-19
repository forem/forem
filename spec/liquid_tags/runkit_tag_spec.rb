require "rails_helper"

RSpec.describe RunkitTag, type: :liquid_template do
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

    def generate_new_liquid(preamble_str, block)
      Liquid::Template.register_tag("runkit", described_class)
      Liquid::Template.parse("{% runkit #{preamble_str}%}#{block}{% endrunkit %}")
    end

    def generate_script(preamble_str, block)
      <<~HTML
        <div class="runkit-element">
          <code style="display: none">#{preamble_str}</code>
          <code>#{block}</code>
        </div>
      HTML
    end

    it "generates proper div with content" do
      liquid = generate_new_liquid(preamble, content)
      expect(liquid.render).to eq(generate_script(preamble, content))
    end
  end
end
