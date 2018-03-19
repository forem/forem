require "rails_helper"

RSpec.describe RunkitTag, type: :liquid_template do
  describe "#render" do
    let(:content) do
      <<~CODE
        // GeoJSON!
        var getJSON = require("async-get-json");

        await getJSON("https://storage.googleapis.com/maps-devrel/google.json");
      CODE
    end

    def generate_new_liquid(block)
      Liquid::Template.register_tag("runkit", described_class)
      Liquid::Template.parse("{% runkit %}#{block}{% endrunkit %}")
    end

    def generate_script(block)
      <<~HTML
        <div class="runkit-element">
          #{block}
        </div>
      HTML
    end

    it "generates proper div with content" do
      liquid = generate_new_liquid(content)
      expect(liquid.render).to eq(generate_script(content))
    end
  end
end
