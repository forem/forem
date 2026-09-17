require "rails_helper"

RSpec.describe AgentSessionRenderers::MarkdownRenderer do
  describe ".render" do
    it "renders basic markdown" do
      expect(described_class.render("Hello **world**")).to include("<strong>world</strong>")
    end

    it "adds no heading ids without a scope (legacy behaviour)" do
      html = described_class.render("## Intro")
      expect(html).to include("<h2>Intro</h2>")
      expect(html).not_to include("id=")
    end

    context "with a session scope" do
      let(:scope) { "agent-session-238" }

      it "adds scoped ids to headings" do
        html = described_class.render("## Intro", scope: scope)
        expect(html).to include(%(<h2 id="agent-session-238-intro">Intro</h2>))
      end

      it "slugs headings GitHub-style so agent table-of-contents links resolve" do
        html = described_class.render("## Work through a small-business example", scope: scope)
        expect(html).to include('id="agent-session-238-work-through-a-small-business-example"')
      end

      it "rewrites fragment links to the scoped heading id when the target exists" do
        text = <<~MD
          - [Intro](#intro)

          ## Intro

          Body
        MD
        html = described_class.render(text, scope: scope)
        expect(html).to include('href="#agent-session-238-intro"')
        expect(html).to include('id="agent-session-238-intro"')
      end

      it "leaves fragment links untouched when no matching heading exists" do
        html = described_class.render("[Elsewhere](#elsewhere)", scope: scope)
        expect(html).to include('href="#elsewhere"')
        expect(html).not_to include("agent-session-238-elsewhere")
      end

      it "leaves external links untouched" do
        html = described_class.render("[dev](https://dev.to)", scope: scope)
        expect(html).to include('href="https://dev.to"')
      end

      it "suffixes duplicate heading ids GitHub-style (-2, -3)" do
        html = described_class.render("## Same\n\na\n\n## Same\n\nb", scope: scope)
        expect(html).to include('id="agent-session-238-same"')
        expect(html).to include('id="agent-session-238-same-2"')
      end

      it "deduplicates ids across separate text blocks of the same session" do
        used_ids = {}
        described_class.render("## Same", scope: scope, used_ids: used_ids)
        html = described_class.render("## Same", scope: scope, used_ids: used_ids)
        expect(html).to include('id="agent-session-238-same-2"')
      end

      it "keeps the id attribute allowed through the sanitizer" do
        html = described_class.render("## Intro", scope: scope)
        # If the sanitizer stripped ids, this would render <h2>Intro</h2>
        expect(html).to include('id="agent-session-238-intro"')
      end
    end
  end
end
