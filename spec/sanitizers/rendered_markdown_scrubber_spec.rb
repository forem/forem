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

  describe "mermaid diagram blocks" do
    it "keeps data-lang on a pre" do
      html = %(<pre data-lang="mermaid"><code>graph TD;</code></pre>)
      expect(clean(html)).to include('data-lang="mermaid"')
    end

    it "strips class from a pre, which is why data-lang is the hook" do
      html = %(<pre class="mermaid"><code>graph TD;</code></pre>)
      output = clean(html)

      expect(output).not_to include("class")
      expect(output).to include("<pre>")
    end
  end

  describe "codeblock attribute scrubbing" do
    it "strips event handlers from non-codeblock elements with class='highlight'" do
      html = %(<img class="highlight" src="https://example.com/x.png" onerror="alert(1)">)
      output = clean(html)

      expect(output).not_to include("onerror")
      expect(output).not_to include("alert(1)")
      expect(output).not_to include("class")
    end

    it "strips event handlers from codeblock elements while keeping highlight classes" do
      html = '<div class="highlight"><pre class="highlight ruby" onclick="alert(1)">' \
             '<code class="highlight" onmouseover="alert(2)">' \
             '<span class="k" onclick="alert(3)">def</span></code></pre></div>'
      output = clean(html)

      expect(output).to include('class="highlight ruby"')
      expect(output).to include('class="k"')
      expect(output).not_to include("onclick")
      expect(output).not_to include("onmouseover")
      expect(output).not_to include("alert")
    end

    it "strips liquid tag syntax from attributes inside codeblocks" do
      html = %(<pre class="highlight {% cta %}"><code class="highlight"><span class="k {% raw %}">x</span></code></pre>)
      output = clean(html)

      expect(output).not_to include("{%")
      expect(output).not_to include("%}")
    end
  end
end
