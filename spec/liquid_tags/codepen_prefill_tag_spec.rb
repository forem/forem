require "rails_helper"

RSpec.describe CodepenPrefillTag, type: :liquid_template do
  describe "#render" do
    let(:options) { "height=500 theme-id=dark default-tab='js,result' editable=true stylesheets=website.com/bootstrap.css,webpage.com/normalize.css scripts=website.com/react.js,webpage.com/react-dom.js" }

    let(:content) do
      <<~HTML
        <pre data-lang="html">
          <h3>Whos that Pokemon?</h3>
          <div id="pokemon"></div>
        </pre>
        <pre data-lang="scss">
          .pokemon {
            color: red;
            font-size: 24px;
          }
        </pre>
        <pre data-lang="js">
          var pokemon_name = "Charizard";
          document.getElementById("pokemon").innerHTML = pokemon_name;
        </pre>
      HTML
    end

    def generate_new_liquid(options_str, block)
      Liquid::Template.register_tag("codepenprefill", CodepenPrefillTag)
      Liquid::Template.parse("{% codepenprefill #{options_str} %}#{block}{% endcodepenprefill %}")
    end

    # do not change HTML format, will make this test fail. Annoying whitespace issue.
    def generate_codepen(block)
      <<~HTML
        <div
          class="codepen"
          data-prefill='{"stylesheets":["website.com/bootstrap.css","webpage.com/normalize.css"],"scripts":["website.com/react.js","webpage.com/react-dom.js"]}'
           data-height=500 data-theme-id=dark data-default-tab='js,result' data-editable=true
          >
          <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html><body>
        #{block}</body></html>

        </div>
        <script async src="https://static.codepen.io/assets/embed/ei.js"></script>
      HTML
    end

    it "generates proper div with content" do
      liquid = generate_new_liquid(options, content)
      codepen_prefill_html = liquid.render
      expect(codepen_prefill_html).to eq(generate_codepen(content))
    end
  end
end
