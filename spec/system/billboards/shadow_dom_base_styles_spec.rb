require "rails_helper"

RSpec.describe "Billboard Shadow DOM base styles", :js do
  def visit_billboards(*billboards)
    body = billboards.map do |id, html|
      Billboards::ShadowDomWrapper.call(html, billboard_id: id, template: "authorship_box")
    end.join
    visit "data:text/html;charset=utf-8,#{ERB::Util.url_encode("<!doctype html><html><body>#{body}</body></html>")}"
  end

  def shadow_style(billboard_id, selector, property)
    evaluate_script(<<~JS)
      (() => {
        const host = document.querySelector('[data-billboard-id="#{billboard_id}"]');
        const target = #{selector == ':host' ? 'host' : "host.shadowRoot.querySelector(#{selector.to_json})"};
        return getComputedStyle(target).getPropertyValue(#{property.to_json});
      })()
    JS
  end

  let(:markup) { '<p>Copy</p><a class="cta" href="/x">Go</a>' }

  it "applies the layered defaults when the author does not override them", :aggregate_failures do
    visit_billboards([1, markup])

    expect(shadow_style(1, "p", "margin-bottom")).to eq("16px")
    expect(shadow_style(1, ".cta", "text-decoration-line")).to eq("underline")
  end

  it "lets low-specificity unlayered author rules beat the base defaults", :aggregate_failures do
    author_css = "<style>.cta { color: rgb(255, 0, 0); text-decoration: none; } p { margin: 0; }</style>"
    visit_billboards([1, markup], [2, author_css + markup])

    expect(shadow_style(1, ".cta", "color")).not_to eq("rgb(255, 0, 0)")
    expect(shadow_style(2, ".cta", "color")).to eq("rgb(255, 0, 0)")
    expect(shadow_style(2, ".cta", "text-decoration-line")).to eq("none")
    expect(shadow_style(2, "p", "margin-bottom")).to eq("0px")
  end

  it "lets author cascade layers beat the base defaults" do
    visit_billboards([1, "<style>@layer promo { p { margin: 0; } }</style>#{markup}"])

    expect(shadow_style(1, "p", "margin-bottom")).to eq("0px")
  end

  it "keeps the :host isolation rules enforced against author overrides", :aggregate_failures do
    author_css = <<~HTML
      <style>
        :host { display: inline !important; min-width: 900px !important; max-width: none !important; }
        @layer promo { :host { contain: none !important; } }
        @layer forem-billboard-base { :host { isolation: auto !important; } }
      </style>
    HTML
    visit_billboards([1, author_css + markup])

    expect(shadow_style(1, ":host", "display")).to eq("block")
    expect(shadow_style(1, ":host", "min-width")).to eq("0px")
    expect(shadow_style(1, ":host", "max-width")).to eq("100%")
    expect(shadow_style(1, ":host", "contain")).to eq("layout style")
    expect(shadow_style(1, ":host", "isolation")).to eq("isolate")
  end
end
