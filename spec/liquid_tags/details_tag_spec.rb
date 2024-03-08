require "rails_helper"

RSpec.describe DetailsTag, type: :liquid_tag do
  describe "#render" do
    def generate_details_liquid(summary, content)
      Liquid::Template.register_tag("details", described_class)
      Liquid::Template.parse("{% details #{summary} %} #{content} {% enddetails %}")
    end

    context "when content has simple text" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "The answer is Forem!" }

      it "generates proper details div with summary" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<details")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a strong tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<strong>foo</strong>" }

      it "accepts a strong tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<strong>foo</strong>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a link tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<a href=\"https://example.com\">link</a>" }

      it "accepts a link tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<a href=\"https://example.com\">link</a>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a h2 tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<h2>heading</h2>" }

      it "accepts a h2 tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<h2>heading</h2>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a list" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<ol><li>one</li><li>two</li></ol>" }

      it "accepts a list tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<li>one</li>")
        expect(rendered).to include("<li>two</li>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has an img tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<img src=\"https://example.com/foo.png\" alt=\"\">" }

      it "accepts an img tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<img src=\"https://example.com/foo.png\" alt=\"\">")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a code tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<code>aaaa</code>" }

      it "accepts a code tag" do
        rendered = generate_details_liquid(summary, content).render

        expect(rendered).to include("<code>aaaa</code>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has a div tag" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<div class=\"highlight\">foo<div>" }

      it "removes a div tag" do
        rendered = generate_details_liquid(summary, content).render
        expect(rendered).not_to include("div")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has unpermitted tags" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<script>alert(1)</script><object>foo</object>" }

      it "removes unpermitted tags" do
        rendered = generate_details_liquid(summary, content).render
        expect(rendered).not_to include("script")
        expect(rendered).not_to include("object")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has an unpermitted attribute" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<p alt=\"alt\" onclick=\"javascript:alert(1)\">foo</p>" }

      it "removes an unpermitted attribute" do
        rendered = generate_details_liquid(summary, content).render
        expect(rendered).not_to include("onclick")
        expect(rendered).to include("<p alt=\"alt\">foo</p>")
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end

    context "when content has tags for creating a code block" do
      let(:summary) { "Click to see the answer!" }
      let(:content) { "<div class=\"highlight\"><pre class=\"highlight plaintext\"><code>foo</code></pre></div>" }

      it "accepts these tags" do
        rendered = generate_details_liquid(summary, content).render
        expect(rendered).to include(
          "<div class=\"highlight\"><pre class=\"highlight plaintext\"><code>foo</code></pre></div>",
        )
        expect(rendered).to include("<summary>Click to see the answer!")
      end
    end
  end
end
