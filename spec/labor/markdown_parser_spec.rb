require "rails_helper"

RSpec.describe MarkdownParser do
  let(:random_word) { Faker::Lorem.word }
  let(:basic_parsed_markdown) { described_class.new(random_word) }

  def generate_and_parse_markdown(raw_markdown)
    described_class.new(raw_markdown).finalize
  end

  it "renders plain text as-is" do
    expect(basic_parsed_markdown.finalize).to include(random_word)
  end

  it "escapes liquid tags in codeblock" do
    code_block = "```\n{% what %}\n```"
    expect(generate_and_parse_markdown(code_block)).to include("{% what %}")
  end

  it "escapes liquid tags in code spans" do
    code_span = "``{% what %}``"
    expect(generate_and_parse_markdown(code_span)).to include("{% what %}")
  end

  it "renders double backtick code spans properly" do
    code_span = "``#{random_word}``"
    expect(generate_and_parse_markdown(code_span)).to include random_word
  end

  it "renders a double backtick codespan with a word wrapped in single backticks properly" do
    code_span = "`` `#{random_word}` ``"
    expect(generate_and_parse_markdown(code_span)).to include "`#{random_word}`"
  end

  it "escapes liquid tags in inline code" do
    inline_code = "`{% what %}`"
    expect(generate_and_parse_markdown(inline_code)).to include(inline_code[1..-2])
  end

  it "raises an error if it detects a XSS attempt" do
    expect { generate_and_parse_markdown("data:text/html") }.to raise_error(ArgumentError)
  end

  context "when provided with an @username" do
    it "links to a user if user exist" do
      username = create(:user).username
      with_user = "@#{username}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a").to_s).to include("/#{username}")
    end

    it "doesn't link to a user if user doesn't exist" do
      with_user = "@#{random_word}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a")).to be_empty
    end
  end

  context "when provided with nested links" do
    it "does not generated nested link tags" do
      nested_links = generate_and_parse_markdown("[[](http://b)](http://a)")
      nested_links = Nokogiri::HTML(nested_links).at("p").inner_html
      expect(nested_links).to eq('[<a href="http://b"></a>](<a href="http://a">http://a</a>)')
    end
  end

  context "when provided with liquid tags" do
    it "raises error if liquid tag was used incorrectly" do
      bad_ltag = "{% #{random_word} %}"
      expect { generate_and_parse_markdown(bad_ltag) }.to raise_error(StandardError)
    end
  end

  context "when provided with kbd tag" do
    it "leaves the kbd tag in place" do
      inline_kbd = generate_and_parse_markdown("<kbd>Ctrl</kbd> + <kbd>,</kbd>")
      inline_kbd = Nokogiri::HTML(inline_kbd).at("p").inner_html
      expect(inline_kbd).to eq("<kbd>Ctrl</kbd> + <kbd>,</kbd>")
    end
  end

  describe "#tags_used" do
    let(:parsed_markdown) { described_class.new("{% youtube oHg5SJYRHA0 %}") }

    it "returns empty if no tag was used" do
      expect(basic_parsed_markdown.tags_used).to eq([])
    end

    it "return tags used if it was used" do
      expect(parsed_markdown.tags_used).to eq([YoutubeTag])
    end
  end

  context "when using gifs from Giphy as images" do
    let(:giphy_markdown_texts) do
      %w(
        ![source](https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif)
        ![social](https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif)
        ![small](https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/200w_d.gif)
      )
    end

    it "does not wrap giphy images with Cloudinary" do
      giphy_markdown_texts.each do |body_markdown|
        html = Nokogiri::HTML(generate_and_parse_markdown(body_markdown))
        img_src = html.search("img")[0]["src"]
        expect(img_src).not_to include("https://res.cloudinary.com")
      end
    end

    it "uses the raw gif from i.giphy.com" do
      giphy_markdown_texts.each do |body_markdown|
        html = Nokogiri::HTML(generate_and_parse_markdown(body_markdown))
        img_src = html.search("img")[0]["src"]
        expect(img_src).to start_with("https://i.giphy.com")
      end
    end
  end

  context "when an image is used" do
    let(:markdown_with_img) { "![](https://image.com/image.jpg)" }

    it "wraps image in link" do
      expect(generate_and_parse_markdown(markdown_with_img)).to include("<a")
    end

    it "wraps the image with Cloudinary" do
      expect(generate_and_parse_markdown(markdown_with_img)).
        to include("https://res.cloudinary.com")
    end
  end

  context "when a colon emoji is used" do
    it "doesn't change text in codeblock" do
      result = generate_and_parse_markdown("<span>:o:<code>:o:</code>:o:<code>:o:</code>:o:<span>:o:</span>:o:</span>")
      expect(result).to include("<span>⭕️<code>:o:</code>⭕️<code>:o:</code>⭕️<span>⭕️</span>⭕️</span>")
    end
  end

  context "when using Liquid variables" do
    it "prevents Liquid variables" do
      expect { generate_and_parse_markdown("{{ 'something' }}") }.to raise_error(StandardError)
    end

    it "allows Liquid variables in codeblocks" do
      expect { generate_and_parse_markdown("```\n{{ 'something' }}\n```") }.not_to raise_error
    end

    it "renders the text in the codeblock properly" do
      result = generate_and_parse_markdown("```\n{{ 'something' }}\n```")
      expect(result).to include("{{ 'something' }}")
    end

    it "allows Liquid variables within inline code" do
      expect { generate_and_parse_markdown("`{{ 'something' }}`") }.not_to raise_error
    end

    it "renders the inline code with the text properly" do
      result = generate_and_parse_markdown("`{{ 'something' }}`")
      expect(result).to include("{{ 'something' }}")
    end

    it "renders nested lists without linebreaks" do
      result = generate_and_parse_markdown("- [A](#a)\n  - [B](#b)\n- [C](#c)")
      expect(result).not_to include("<br>")
    end

    it "permits abbr and aside tags" do
      result = generate_and_parse_markdown("<aside><abbr title=\"ol korrect\">OK</abbr><aside>")
      expect(result).to include("<aside><abbr title=\"ol korrect\">OK</abbr><aside>")
    end
  end
end
