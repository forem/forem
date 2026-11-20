require "rails_helper"

RSpec.describe AgentSessionRenderers::MarkdownRenderer do
  let(:toc_markdown) do
    <<~MARKDOWN
      ## Table of Contents

      - [Getting Started](#getting-started)
      - [FAQ & Troubleshooting](#faq--troubleshooting)
      - [Nowhere](#nowhere)

      ## Getting Started

      Some text.

      ## FAQ & Troubleshooting

      More text.
    MARKDOWN
  end

  describe ".render" do
    it "styles redactions inside prose and plain fences and preserves HTML escaping", :aggregate_failures do
      html = described_class.render("[REDACTED]\n\n```\n<script>alert(1)</script> [REDACTED]\n```")

      expect(html).to be_html_safe
      expect(html.scan('class="agent-session-redacted"').length).to eq(2)
      expect(html).to include('<pre class="highlight"><code>')
      expect(html).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
      expect(html).not_to include("<script>")
    end

    it "matches legacy rendering across 1,000 seeded transcripts including Rouge blocks" do
      rng = Random.new(424_242)
      fragments = [
        "", "日本語 🚀\r\n[REDACTED]", "# Heading\n\n[local](#heading)",
        "```\nplain & <tag> [REDACTED]\n```", "```ruby\nputs :hello\n```",
        "```unknown_language\n[REDACTED] & value\n```", "```c++\nint x = 1;\n```",
        "<script>alert('unsafe')</script>", "**bold** `code` [REDACTED]",
        "| a | b |\n|---|---|\n| [REDACTED] | &amp; |"
      ]
      transcripts = Array.new(1_000) do
        Array.new(rng.rand(0..5)) { fragments.sample(random: rng) }.join("\n\n")
      end
      native_results = transcripts.map { |text| described_class.render(text) }
      allow(ForemNative).to receive(:postprocess_transcript_html).and_return(nil)

      transcripts.zip(native_results).each do |text, actual|
        expected = described_class.render(text)
        expect(actual).to eq(expected)
        expect(actual).to be_html_safe
      end
    end

    it "uses the legacy path when the platform binary lacks the new symbol" do
      allow(ForemNative::Native).to receive(:respond_to?).and_call_original
      allow(ForemNative::Native).to receive(:respond_to?).with(:postprocess_transcript_html).and_return(false)

      expect(ForemNative.postprocess_transcript_html("[REDACTED]")).to be_nil
      expect(described_class.render("[REDACTED]")).to include(
        '<span class="agent-session-redacted">[REDACTED]</span>',
      )
    end

    context "without heading anchors" do
      it "renders headings without ids" do
        html = described_class.render("## Getting Started")
        expect(html).to include("<h2>Getting Started</h2>")
        expect(html).not_to include("id=")
      end
    end

    context "with heading anchors" do
      let(:anchors) { AgentSessionRenderers::HeadingAnchors.new("agent-session-5-2") }

      it "gives headings scoped ids and points the table of contents at them" do
        html = described_class.render(toc_markdown, heading_anchors: anchors)

        expect(html).to include('<h2 id="agent-session-5-2-getting-started">Getting Started</h2>')
        expect(html).to include('<h2 id="agent-session-5-2-faq--troubleshooting">FAQ &amp; Troubleshooting</h2>')
        expect(html).to include('<a href="#agent-session-5-2-getting-started">Getting Started</a>')
        expect(html).to include('<a href="#agent-session-5-2-faq--troubleshooting">FAQ &amp; Troubleshooting</a>')
      end

      it "leaves fragment links without a matching heading untouched" do
        html = described_class.render(toc_markdown, heading_anchors: anchors)
        expect(html).to include('<a href="#nowhere">Nowhere</a>')
      end

      it "does not let transcript text inject its own ids" do
        html = described_class.render(%(<h2 id="currentUser">x</h2>\n\n## Real), heading_anchors: anchors)
        ids = Nokogiri::HTML.fragment(html).css("[id]").pluck("id")
        expect(ids).to eq(["agent-session-5-2-real"])
      end
    end
  end

  describe ".highlight_code_blocks" do
    it "keeps markers literal by default for existing callers" do
      expect(described_class.highlight_code_blocks("<pre><code>[REDACTED]</code></pre>")).to eq(
        '<pre class="highlight"><code>[REDACTED]</code></pre>',
      )
    end

    it "preserves syntax highlight error recovery before styling markers" do
      allow(ForemNative).to receive(:syntax_highlight_html).with("<tag> [REDACTED]", "ruby").and_raise(StandardError)
      html = '<pre><code class="ruby">&lt;tag&gt; [REDACTED]</code></pre>'

      expect(described_class.highlight_code_blocks(html, redact: true)).to eq(
        '<pre class="highlight"><code>&lt;tag&gt; ' \
        '<span class="agent-session-redacted">[REDACTED]</span></code></pre>',
      )
    end

    it "retains the legacy invalid UTF-8 error" do
      expect do
        described_class.highlight_code_blocks("\xFF".force_encoding("UTF-8"))
      end.to raise_error(ArgumentError, /invalid byte sequence/)
    end
  end
end
