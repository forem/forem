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
end
