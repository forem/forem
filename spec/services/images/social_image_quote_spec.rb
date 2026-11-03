require "rails_helper"

RSpec.describe Images::SocialImageQuote do
  def quote(html, title: "A Post Title")
    described_class.from_html(html, title)
  end

  describe ".call" do
    it "reads the article's processed HTML and title" do
      article = build(:article, title: "Title")
      article.processed_html = "<p>#{'Opening words. ' * 6}</p>"
      expect(described_class.call(article)).to start_with("Opening words.")
    end
  end

  describe ".from_html" do
    it "uses the first paragraph when it is long enough" do
      first = "When an AI agent commits a change to code, it makes a claim about what it changed."
      expect(quote("<p>#{first}</p><p>Second paragraph.</p>")).to eq(first)
    end

    it "joins short opening paragraphs until the quote is long enough" do
      html = "<p>I used to run an ecommerce brand.</p>" \
             "<p>In small ecommerce, marketing is everything, and it comes in two kinds.</p><p>Not this.</p>"
      expected = "I used to run an ecommerce brand. " \
                 "In small ecommerce, marketing is everything, and it comes in two kinds."
      expect(quote(html)).to eq(expected)
    end

    it "skips paragraphs that are entirely italic, such as challenge submission intros" do
      html = "<p><em>This is a submission for the <a href='#'>Some Challenge</a></em></p>" \
             "<p>We all have that one moment in life that makes us smile whenever we think about it.</p>"
      expect(quote(html)).to eq("We all have that one moment in life that makes us smile whenever we think about it.")
    end

    it "skips a paragraph that repeats the title" do
      html = "<p><strong>A Post Title</strong></p><p>#{'Real opening text. ' * 5}</p>"
      expect(quote(html)).to start_with("Real opening text.")
    end

    it "ignores headings, code blocks, images, and blockquotes" do
      html = "<h2>Heading</h2><div class='highlight'><pre>code</pre></div>" \
             "<blockquote><p>Someone else's words.</p></blockquote>" \
             "<p><img src='x.png' alt='image'></p><p>#{'The author speaking. ' * 5}</p>"
      expect(quote(html)).to start_with("The author speaking.")
    end

    it "cuts long text at the last sentence boundary that fits" do
      first = "This first sentence is long enough to stand on its own as a quote for the card."
      html = "<p>#{first} #{'And then the second sentence keeps going and going ' * 4}until it ends.</p>"
      expect(quote(html)).to eq(first)
    end

    it "cuts at a word with an ellipsis when no sentence boundary fits" do
      text = "word " * 60
      result = quote("<p>#{text}</p>")
      expect(result.length).to be <= described_class::MAX_LENGTH
      expect(result).to end_with("word\u2026")
    end

    it "normalizes stylized Unicode letters and drops emoji the fonts cannot render" do
      html = "<p>\u{1D413}\u{1D421}\u{1D41E} best moment \u{1F525} of my whole life, " \
             "and I keep thinking about it every day.</p>"
      expect(quote(html)).to eq("The best moment of my whole life, and I keep thinking about it every day.")
    end

    it "falls back to the title when the body has no usable paragraph" do
      expect(quote("<div class='highlight'><pre>code only</pre></div>", title: "Only Code")).to eq("Only Code")
    end

    it "falls back to the raw title when both body and cleaned title are empty" do
      html = "<div class='highlight'><pre>code only</pre></div>"
      expect(quote(html, title: "\u{1F525}\u{1F525}")).to eq("\u{1F525}\u{1F525}")
    end
  end
end
