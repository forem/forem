require "rails_helper"

RSpec.describe Articles::QuickieFormatter, type: :service do
  def render(text, links: false)
    escaped = text.gsub("<", "&lt;").gsub(">", "&gt;")
    described_class.render(escaped, links: links) { |prepared| prepared }
  end

  describe "formatting" do
    it "renders bold, italic and underline" do
      expect(render("**bold** *italic* _also italic_ __underline__"))
        .to eq("<strong>bold</strong> <em>italic</em> <em>also italic</em> <u>underline</u>")
    end

    it "supports nesting" do
      expect(render("**bold *and italic* text**")).to eq("<strong>bold <em>and italic</em> text</strong>")
      expect(render("***both***")).to eq("<em><strong>both</strong></em>")
    end

    it "renders links as underlined spans by default, since feed titles are already inside a link" do
      expect(render("see [the docs](https://docs.forem.com/a?b=1)"))
        .to eq(%(see <span style="text-decoration: underline;">the docs</span>))
    end

    it "renders links as anchors with safe attributes when links are enabled" do
      html = render("[docs](https://docs.forem.com/a?b=1&c=2)", links: true)

      expect(html).to eq(
        %(<a href="https://docs.forem.com/a?b=1&amp;c=2" target="_blank" rel="nofollow noopener noreferrer ugc">docs</a>),
      )
    end

    it "formats the label of a link" do
      expect(render("[**docs**](https://docs.forem.com)", links: true)).to include("<strong>docs</strong></a>")
    end
  end

  describe "text that is left alone" do
    [
      "plain text",
      "5 * 3 * 2",
      "snake_case_words and file_name_here",
      "**unclosed bold",
      "* not italic *",
      "[no url]",
      "[label](javascript:alert(1))",
      "[label](ftp://example.com)",
      "",
    ].each do |text|
      it "returns #{text.inspect} unchanged" do
        expect(render(text, links: true)).to eq(text)
      end
    end

    it "does not touch text that cannot be inspected" do
      invalid = "**bold** \xFF".dup.force_encoding("UTF-8")

      expect(described_class.render(invalid) { |prepared| prepared }).to eq(invalid)
    end
  end

  describe "security" do
    it "never lets typed markup through, since the input is already escaped" do
      html = render("<script>alert(1)</script> **<img src=x onerror=alert(1)>**")

      expect(html).not_to include("<script", "<img")
      expect(html).to include("&lt;script&gt;", "<strong>&lt;img src=x onerror=alert(1)&gt;</strong>")
    end

    it "cannot break out of the href attribute" do
      html = render(%([x](https://example.com/"onmouseover="alert(1))), links: true)

      expect(html).not_to include("<a ")
    end

    it "removes placeholder characters typed by the author instead of using them" do
      html = render("0 **x**")

      expect(html).to eq("0 <strong>x</strong>")
    end
  end

  describe "wrapping another renderer" do
    it "formats around the base renderer's output, and the base renderer never sees raw markers" do
      seen = nil
      html = described_class.render("**hi**\n\nthere") do |prepared|
        seen = prepared
        prepared.gsub("\n\n", "<br>")
      end

      expect(seen).not_to include("**")
      expect(html).to eq("<strong>hi</strong><br>there")
    end

    it "drops the placeholder of a formatted span that the base renderer cut off" do
      html = described_class.render("**gone**") { |_prepared| "kept0" }

      expect(html).to eq("kept<strong>gone</strong>")
    end
  end
end
