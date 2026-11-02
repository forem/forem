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

  describe "code spans" do
    it "renders backticked text as code and leaves its contents literal" do
      expect(render("call `__init__` or `2**10**3` or `*x*`"))
        .to eq("call <code>__init__</code> or <code>2**10**3</code> or <code>*x*</code>")
    end

    it "escapes markup inside a code span" do
      expect(render("`<b>bold</b>`")).to eq("<code>&lt;b&gt;bold&lt;/b&gt;</code>")
    end

    it "keeps backslashes inside a code span as typed" do
      expect(render("`a\\*b`")).to eq("<code>a\\*b</code>")
    end

    it "can sit inside bold text" do
      expect(render("**run `rake` now**")).to eq("<strong>run <code>rake</code> now</strong>")
    end

    it "leaves an unclosed backtick alone" do
      expect(render("one ` tick")).to eq("one ` tick")
    end
  end

  describe "backslash escapes" do
    it "shows an escaped marker as plain text" do
      expect(render("\\*not italic\\* and \\_not italic\\_")).to eq("*not italic* and _not italic_")
    end

    it "lets authors write dunder names literally" do
      expect(render("Python's \\_\\_init\\_\\_ method")).to eq("Python's __init__ method")
    end

    it "escapes brackets, backticks and the backslash itself" do
      expect(render("\\[a\\](https://example.com) \\`x\\` \\\\*y*")).to eq("[a](https://example.com) `x` \\<em>y</em>")
    end

    it "does not let an escaped marker open bold text" do
      expect(render("\\**x**")).to eq("**x**")
    end

    it "keeps a backslash before any other character" do
      expect(render("C:\\dir\\file")).to eq("C:\\dir\\file")
    end
  end

  describe "markers inside words" do
    it "leaves exponents and bold-looking markers between word characters alone" do
      expect(render("2**10**3")).to eq("2**10**3")
      expect(render("a**b**c")).to eq("a**b**c")
    end

    it "still renders bold next to punctuation and spaces" do
      expect(render("(**bold**), **bold**!")).to eq("(<strong>bold</strong>), <strong>bold</strong>!")
    end
  end

  describe "URLs" do
    it "leaves a span that contains a URL as text so the base renderer can shorten it" do
      expect(render("**https://example.com/a/very/long/path**")).to eq("**https://example.com/a/very/long/path**")
      expect(render("_see https://example.com_")).to eq("_see https://example.com_")
    end

    it "leaves a link whose label is a URL as text" do
      expect(render("[https://example.com](https://example.com)", links: true))
        .to eq("[https://example.com](https://example.com)")
    end

    it "still formats a span around a link" do
      expect(render("**[docs](https://docs.forem.com)**", links: true))
        .to include("<strong>", "</strong>", "<a href=")
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
