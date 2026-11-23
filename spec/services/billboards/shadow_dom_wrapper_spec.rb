require "rails_helper"

RSpec.describe Billboards::ShadowDomWrapper do
  describe ".call" do
    it "wraps raw billboard HTML in an open Declarative Shadow DOM host with base styles and bootstrapper",
       :aggregate_failures do
      raw_html = '<style>h1 { color: red; }</style><div class="promo"><h1>Hello &amp; Welcome</h1></div>'

      wrapped = described_class.call(raw_html, billboard_id: 42, template: "authorship_box")

      expect(wrapped).to be_html_safe
      expect(wrapped).to include(
        'data-billboard-shadow-host="true"',
        'data-billboard-id="42"',
        'data-billboard-template="authorship_box"',
        '<template shadowrootmode="open">',
        '<style data-billboard-base-styles="true">',
        '<div class="billboard-shadow-body">',
        'data-billboard-shadow-bootstrap="true"',
      )
      expect(wrapped).to include("<style>h1 { color: red; }</style>")
      expect(wrapped).to include("Hello &amp; Welcome")
    end

    it "puts the :host isolation rules first as !important in an anonymous cascade layer", :aggregate_failures do
      isolation_block = described_class::BASE_STYLES[/\A@layer \{ :host \{(?<declarations>[^}]*)\} \}/, :declarations]

      expect(isolation_block).to be_present
      declarations = isolation_block.split(";").map(&:strip).compact_blank
      expect(declarations).to contain_exactly(
        "display: block !important",
        "min-width: 0 !important",
        "max-width: 100% !important",
        "contain: layout style !important",
        "isolation: isolate !important",
      )
    end

    it "keeps every other base rule inside the named, overridable forem-billboard-base layer", :aggregate_failures do
      layered = described_class::BASE_STYLES.sub(/\A@layer \{ :host \{[^}]*\} \} /, "")

      expect(described_class::BASE_LAYER_NAME).to eq("forem-billboard-base")
      expect(layered).to start_with("@layer forem-billboard-base { ")
      expect(layered).to end_with(" }")
      expect(layered.count("{")).to eq(layered.count("}"))
      expect(layered).not_to include("!important")
      expect(layered).to include(".crayons-btn", ".c-cta", ":host([data-billboard-template='authorship_box'])")
    end

    it "emits the base styles before any author markup so author cascade layers are ordered after the base layer" do
      wrapped = described_class.call("<style>@layer promo { p { margin: 0; } }</style><p>Hi</p>", billboard_id: 3)
      template = Nokogiri::HTML5.fragment(wrapped).at_css("template")

      expect(template.children.first.to_html).to start_with('<style data-billboard-base-styles="true">@layer {')
    end

    it "neutralizes executable script tags while preserving non-JS data scripts", :aggregate_failures do
      raw_html = <<~HTML
        <div id="widget"></div>
        <script>if (1 < 2 && 3 > 1) { window.x = 1; }</script>
        <script type="text/javascript">window.y = 2;</script>
        <script type="module">export const z = 3;</script>
        <script src="https://cdn.example.com/widget.js" defer></script>
        <script type="application/json" id="cfg">{"ok":true}</script>
      HTML

      wrapped = described_class.call(raw_html, billboard_id: 7, template: "plain")
      doc = Nokogiri::HTML.fragment(wrapped)
      host = doc.at_css("[data-billboard-shadow-host='true']")
      scripts = host.css("script")

      expect(scripts.size).to eq(5)

      inline_default = scripts[0]
      expect(inline_default["type"]).to eq(described_class::SCRIPT_MIME_TYPE)
      expect(inline_default["data-billboard-script"]).to eq("true")
      expect(inline_default["data-original-type"]).to be_nil
      expect(inline_default.text).to include("if (1 < 2 && 3 > 1)")

      inline_text_js = scripts[1]
      expect(inline_text_js["type"]).to eq(described_class::SCRIPT_MIME_TYPE)
      expect(inline_text_js["data-original-type"]).to eq("text/javascript")

      inline_module = scripts[2]
      expect(inline_module["type"]).to eq(described_class::SCRIPT_MIME_TYPE)
      expect(inline_module["data-original-type"]).to eq("module")

      external_script = scripts[3]
      expect(external_script["type"]).to eq(described_class::SCRIPT_MIME_TYPE)
      expect(external_script["src"]).to be_nil
      expect(external_script["data-billboard-script-src"]).to eq("https://cdn.example.com/widget.js")

      json_script = scripts[4]
      expect(json_script["type"]).to eq("application/json")
      expect(json_script["data-billboard-script"]).to be_nil
      expect(json_script.text).to eq('{"ok":true}')
    end

    it "balances stray closing template tags and strips base and meta refresh footguns", :aggregate_failures do
      raw_html = <<~HTML
        <base href="https://evil.example.com/">
        <meta http-equiv="refresh" content="0;url=https://evil.example.com/">
        <meta name="author" content="DEV">
        <div>Safe copy</template><div>More copy
      HTML

      wrapped = described_class.call(raw_html, billboard_id: 99, template: "plain")

      expect(wrapped).not_to include("<base")
      expect(wrapped).not_to include("http-equiv")
      expect(wrapped).to include('<meta name="author" content="DEV">')
      expect(wrapped.scan("</template>").size).to eq(1)
      expect(wrapped).to include("Safe copy", "More copy")
    end
  end
end
