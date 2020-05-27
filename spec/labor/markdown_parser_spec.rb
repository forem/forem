require "rails_helper"

RSpec.describe MarkdownParser, type: :labor do
  let(:random_word) { Faker::Lorem.word }
  let(:basic_parsed_markdown) { described_class.new(random_word) }

  def generate_and_parse_markdown(raw_markdown)
    described_class.new(raw_markdown).finalize
  end

  xit "renders plain text as-is" do
    expect(basic_parsed_markdown.finalize).to include(random_word)
  end

  xit "escapes liquid tags in codeblock" do
    code_block = "```\n{% what %}\n```"
    expect(generate_and_parse_markdown(code_block)).to include("{% what %}")
  end

  xit "escapes the `raw` Liquid tag in codeblocks" do
    code_block = "```\n{% raw %}some text{% endraw %}\n```"
    expect(generate_and_parse_markdown(code_block)).to include("{% raw %}", "{% endraw %}")
  end

  xit "does not render the escaped dashes when using a `raw` Liquid tag in codeblocks with syntax highlighting" do
    code_block = "```js\n{% raw %}some text{% endraw %}\n```"
    expect(generate_and_parse_markdown(code_block)).not_to include("----")
  end

  xit "does not remove the non-'raw tag related' four dashes" do
    code_block = "```\n----\n```"
    expect(generate_and_parse_markdown(code_block)).to include("----")
  end

  xit "escapes the `raw` Liquid tag in codespans" do
    code_block = "``{% raw %}some text{% endraw %}``"
    expect(generate_and_parse_markdown(code_block)).to include("{% raw %}", "{% endraw %}")
  end

  xit "escapes the `raw` Liquid tag in inline code" do
    code_block = "`{% raw %}some text{% endraw %}`"
    expect(generate_and_parse_markdown(code_block)).to include("{% raw %}", "{% endraw %}")
  end

  xit "escapes codeblocks in numbered lists" do
    code_block = "1. Define your hooks in config file `lefthook.yml`\n
    ```yaml
     pre-push:\n        parallel: true\n        commands:\n        rubocop:
     run: bundle exec rspec --fail-fast\n
    ```"
    escaped_codeblock = generate_and_parse_markdown(code_block)
    expect(escaped_codeblock).not_to include("```")
    expect(escaped_codeblock).not_to include("`")
    expect(escaped_codeblock).to include("bundle exec rspec --fail-fast")
  end

  xit "escapes liquid tags in code spans" do
    code_span = "``{% what %}``"
    expect(generate_and_parse_markdown(code_span)).to include("{% what %}")
  end

  xit "renders double backtick code spans properly" do
    code_span = "``#{random_word}``"
    expect(generate_and_parse_markdown(code_span)).to include random_word
  end

  xit "wraps figcaptions with figures" do
    code_span = "<p>Statement</p>\n<figcaption>A fig</figcaption>"
    test = generate_and_parse_markdown("<p>case: </p>" + code_span)
    expect(test).to eq("<p>case: </p>\n<figure>" + code_span + "</figure>\n\n\n\n")
  end

  xit "does not wrap figcaptions already in figures" do
    code_span = "<figure><p>Statement</p>\n<figcaption>A fig</figcaption></figure>"
    test = generate_and_parse_markdown(code_span)
    expect(test).to eq(code_span + "\n\n\n\n")
  end

  xit "does not wrap figcaptions without predecessors" do
    code_span = "<figcaption>A fig</figcaption>"
    test = generate_and_parse_markdown(code_span)
    expect(test).to eq(code_span + "\n\n")
  end

  context "when rendering links markdown" do
    # the following specs are testing HTMLRouge
    xit "renders properly if protocol http is included" do
      code_span = "[github](http://github.com)"
      test = generate_and_parse_markdown(code_span)
      expect(test).to eq("<p><a href=\"http://github.com\">github</a></p>\n\n")
    end

    xit "renders properly if protocol https is included" do
      code_span = "[github](https://github.com)"
      test = generate_and_parse_markdown(code_span)
      expect(test).to eq("<p><a href=\"https://github.com\">github</a></p>\n\n")
    end

    xit "renders properly if protocol is not included" do
      code_span = "[github](github.com)"
      test = generate_and_parse_markdown(code_span)
      expect(test).to eq("<p><a href=\"//github.com\">github</a></p>\n\n")
    end

    xit "renders properly relative paths" do
      code_span = "[career tag](/t/career)"
      test = generate_and_parse_markdown(code_span)
      app_protocol = ApplicationConfig["APP_PROTOCOL"]
      app_domain = ApplicationConfig["APP_DOMAIN"]
      expect(test).to eq("<p><a href=\"#{app_protocol}#{app_domain}/t/career\">career tag</a></p>\n\n")
    end

    xit "renders properly anchored links" do
      code_span = "[Chapter 1](#chapter-1)"
      test = generate_and_parse_markdown(code_span)
      expect(test).to eq("<p><a href=\"#chapter-1\">Chapter 1</a></p>\n\n")
    end
  end

  describe "mentions" do
    let(:user) { build_stubbed(:user) }

    before { allow(User).to receive(:find_by).with(username: user.username).and_return(user) }

    xit "works normally" do
      mention = "@#{user.username}"
      result = generate_and_parse_markdown(mention)
      expect(result).to include "<a"
    end

    xit "works with undescore" do
      mention = "what was found here _@#{user.username}_ let see"
      result = generate_and_parse_markdown(mention)
      expect(result).to include "<a", "<em"
    end

    xit "works in ul/li tag" do
      mention = <<~DOC
        `@#{user.username}` one two, @#{user.username} three four:
          - `@#{user.username}`
      DOC
      result = generate_and_parse_markdown(mention)
      expect(result).to eq("<p><code>@#{user.username}</code> one two, <a class=\"comment-mentioned-user\" href=\"#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/#{user.username}\">@#{user.username}</a>\n three four:</p>\n\n<ul>\n<li><code>@#{user.username}</code></li>\n</ul>\n\n")
    end

    xit "will not work in code tag" do
      mention = "this is a chunk of text `@#{user.username}`"
      result = generate_and_parse_markdown(mention)
      expect(result).to include "<code"
      expect(result).not_to include "<a"
    end

    xit "works with markdown heavy contents" do
      mention = "test **[link?](https://dev.to/ben/)** thread, @#{user.username} talks :"
      result = generate_and_parse_markdown(mention)
      expect(result).to include "<a class=\"comment-mentioned-user\""
    end
  end

  xit "renders a double backtick codespan with a word wrapped in single backticks properly" do
    code_span = "`` `#{random_word}` ``"
    expect(generate_and_parse_markdown(code_span)).to include "`#{random_word}`"
  end

  xit "escapes liquid tags in inline code" do
    inline_code = "`{% what %}`"
    expect(generate_and_parse_markdown(inline_code)).to include(inline_code[1..-2])
  end

  xit "raises an error if it detects a XSS attempt" do
    expect { generate_and_parse_markdown("data:text/html") }.to raise_error(ArgumentError)
  end

  context "when provided with an @username" do
    xit "links to a user if user exist" do
      username = create(:user).username
      with_user = "@#{username}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a").to_s).to include("/#{username}")
    end

    xit "doesn't link to a user if user doesn't exist" do
      with_user = "@#{random_word}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a")).to be_empty
    end
  end

  context "when provided with nested links" do
    xit "does not generated nested link tags" do
      nested_links = generate_and_parse_markdown("[[](http://b)](http://a)")
      nested_links = Nokogiri::HTML(nested_links).at("p").inner_html
      expect(nested_links).to eq('[<a href="http://b"></a>](<a href="http://a">http://a</a>)')
    end
  end

  context "when provided with liquid tags" do
    xit "does not raises error if liquid tag was used incorrectly" do
      bad_ltag = "{% #{random_word} %}"
      expect { generate_and_parse_markdown(bad_ltag) }.not_to raise_error
    end
  end

  context "when provided with kbd tag" do
    xit "leaves the kbd tag in place" do
      inline_kbd = generate_and_parse_markdown("<kbd>Ctrl</kbd> + <kbd>,</kbd>")
      inline_kbd = Nokogiri::HTML(inline_kbd).at("p").inner_html
      expect(inline_kbd).to eq("<kbd>Ctrl</kbd> + <kbd>,</kbd>")
    end
  end

  describe "#tags_used" do
    let(:parsed_markdown) { described_class.new("{% youtube oHg5SJYRHA0 %}") }

    xit "returns empty if no tag was used" do
      expect(basic_parsed_markdown.tags_used).to eq([])
    end

    xit "return tags used if it was used" do
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

    xit "does not wrap giphy images with Cloudinary" do
      giphy_markdown_texts.each do |body_markdown|
        html = Nokogiri::HTML(generate_and_parse_markdown(body_markdown))
        img_src = html.search("img")[0]["src"]
        expect(img_src).not_to include("https://res.cloudinary.com")
      end
    end

    xit "uses the raw gif from i.giphy.com" do
      giphy_markdown_texts.each do |body_markdown|
        html = Nokogiri::HTML(generate_and_parse_markdown(body_markdown))
        img_src = html.search("img")[0]["src"]
        expect(img_src).to start_with("https://i.giphy.com")
      end
    end
  end

  context "when an image is used" do
    let(:markdown_with_img) { "![](https://image.com/image.jpg)" }

    xit "wraps image in link" do
      expect(generate_and_parse_markdown(markdown_with_img)).to include("<a")
    end

    xit "wraps the image with Cloudinary" do
      expect(generate_and_parse_markdown(markdown_with_img)).
        to include("https://res.cloudinary.com")
    end
  end

  context "when a colon emoji is used" do
    xit "doesn't change text in codeblock" do
      result = generate_and_parse_markdown("<span>:o:<code>:o:</code>:o:<code>:o:</code>:o:<span>:o:</span>:o:</span>")
      expect(result).to include("<span>⭕<code>:o:</code>⭕<code>:o:</code>⭕<span>⭕</span>⭕</span>")
    end
  end

  context "when using Liquid variables" do
    xit "prevents Liquid variables" do
      expect { generate_and_parse_markdown("{{ 'something' }}") }.to raise_error(StandardError)
    end

    xit "allows Liquid variables in codeblocks" do
      expect { generate_and_parse_markdown("```\n{{ 'something' }}\n```") }.not_to raise_error
    end

    xit "renders the text in the codeblock properly" do
      result = generate_and_parse_markdown("```\n{{ 'something' }}\n```")
      expect(result).to include("{{ 'something' }}")
    end

    xit "allows Liquid variables within inline code" do
      expect { generate_and_parse_markdown("`{{ 'something' }}`") }.not_to raise_error
    end

    xit "renders the inline code with the text properly" do
      result = generate_and_parse_markdown("`{{ 'something' }}`")
      expect(result).to include("{{ 'something' }}")
    end

    xit "renders nested lists without linebreaks" do
      result = generate_and_parse_markdown("- [A](#a)\n  - [B](#b)\n- [C](#c)")
      expect(result).not_to include("<br>")
    end

    xit "permits abbr and aside tags" do
      result = generate_and_parse_markdown("<aside><abbr title=\"ol korrect\">OK</abbr><aside>")
      expect(result).to include("<aside><abbr title=\"ol korrect\">OK</abbr><aside>")
    end
  end

  context "when word as snake case" do
    xit "doesn't change word" do
      code_block = "word_italic_"
      expect(generate_and_parse_markdown(code_block)).to include("word_italic_")
    end
  end

  context "when double underline" do
    xit "renders italic" do
      code_block = "word__italic__"
      expect(generate_and_parse_markdown(code_block)).to include("word_<em>italic</em>_")
    end
  end

  context "when adding syntax highlighting" do
    xit "defaults to plaintext" do
      code_block = "```\ntext\n````"
      expect(generate_and_parse_markdown(code_block)).to include("highlight plaintext")
    end

    xit "adds correct syntax highlighting to codeblocks when the hint is not lowercase" do
      code_block = "```Ada\nwith Ada.Directories;\n````"
      expect(generate_and_parse_markdown(code_block)).to include("highlight ada")
    end

    xit "adds correct syntax highlighting to codeblocks when the hint is lowercase" do
      code_block = "```ada\nwith Ada.Directories;\n````"
      expect(generate_and_parse_markdown(code_block)).to include("highlight ada")
    end
  end
end
