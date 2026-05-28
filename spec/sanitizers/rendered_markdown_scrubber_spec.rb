require "rails_helper"

RSpec.describe RenderedMarkdownScrubber, type: :permit_scrubber do
  include ActionView::Helpers::SanitizeHelper

  def clean(html)
    sanitize(html, scrubber: described_class.new)
  end

  describe "table cell text-align" do
    %w[left center right].each do |alignment|
      it "keeps text-align: #{alignment} on a td" do
        html = %(<table><tbody><tr><td style="text-align: #{alignment}">x</td></tr></tbody></table>)
        expect(clean(html)).to include(%(style="text-align: #{alignment}"))
      end

      it "keeps text-align: #{alignment} on a th" do
        html = %(<table><thead><tr><th style="text-align: #{alignment}">x</th></tr></thead></table>)
        expect(clean(html)).to include(%(style="text-align: #{alignment}"))
      end
    end

    it "drops non-text-align declarations on a td but keeps the alignment" do
      html = %(<table><tbody><tr><td style="background: red; text-align: center">x</td></tr></tbody></table>)
      output = clean(html)

      expect(output).to include("text-align: center")
      expect(output).not_to include("background")
    end

    it "removes the style attribute entirely when no allowed declaration remains" do
      html = %(<table><tbody><tr><td style="background: red">x</td></tr></tbody></table>)
      expect(clean(html)).not_to include("style")
    end

    it "rejects a non-keyword text-align value" do
      html = %(<table><tbody><tr><td style="text-align: expression(alert(1))">x</td></tr></tbody></table>)
      output = clean(html)

      expect(output).not_to include("expression")
      expect(output).not_to include("style")
    end

    it "rejects a url() text-align value" do
      html = %(<table><tbody><tr><td style="text-align: url(javascript:alert(1))">x</td></tr></tbody></table>)
      output = clean(html)

      expect(output).not_to include("url(")
      expect(output).not_to include("style")
    end
  end

  describe "style on non-table elements" do
    it "strips style from a paragraph even when it is a valid text-align" do
      html = %(<p style="text-align: center">x</p>)
      expect(clean(html)).not_to include("style")
    end

    it "strips style from a span carrying a dangerous declaration" do
      html = %(<span style="background: url(javascript:alert(1))">x</span>)
      output = clean(html)

      expect(output).not_to include("style")
      expect(output).not_to include("javascript")
    end
  end
end
