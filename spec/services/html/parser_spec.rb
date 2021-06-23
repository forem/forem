require "rails_helper"

RSpec.describe Html::Parser, type: :service do
  it "has the correct raw tag delimiters" do
    expect(described_class::RAW_TAG_DELIMITERS).to match_array(["{", "}", "raw", "endraw", "----"])
  end

  describe "#remove_nested_linebreak_in_list" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).remove_nested_linebreak_in_list.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").remove_nested_linebreak_in_list.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").remove_nested_linebreak_in_list
      expect(html_parser).to be_a described_class
    end

    it "renders nested lists without linebreaks" do
      html = "- [A](#a)\n  - [B](#b)\n- [C](#c)"
      parsed_html = described_class.new(html).remove_nested_linebreak_in_list.html
      expect(parsed_html).not_to include("<br>")
    end
  end

  describe "#prefix_all_images" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).prefix_all_images.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").prefix_all_images.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").prefix_all_images
      expect(html_parser).to be_a described_class
    end

    context "when using gifs from Giphy as images" do
      it "does not wrap giphy images with Cloudinary" do
        html = "<img src='https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif'>"
        parsed_html = Nokogiri::HTML(described_class.new(html).prefix_all_images.html)
        img_src = parsed_html.search("img")[0]["src"]
        expect(img_src).not_to include("https://res.cloudinary.com")
      end

      it "uses the raw gif from i.giphy.com" do
        html = "<img src='https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif'>"
        parsed_html = Nokogiri::HTML(described_class.new(html).prefix_all_images.html)
        img_src = parsed_html.search("img")[0]["src"]
        expect(img_src).to start_with("https://i.giphy.com")
      end
    end

    context "when an image is used" do
      it "wraps the image with Cloudinary" do
        html = "<img src='https://image.com/image.jpg'>"
        parsed_html = described_class.new(html).prefix_all_images.html
        expect(parsed_html).to include("https://res.cloudinary.com")
      end
    end
  end

  describe "#wrap_all_images_in_links" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).wrap_all_images_in_links.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").wrap_all_images_in_links.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").wrap_all_images_in_links
      expect(html_parser).to be_a described_class
    end

    it "wraps image in link" do
      html = "<p><img src='https://image.com/image.jpg'></p"
      parsed_html = described_class.new(html).wrap_all_images_in_links.html
      expect(parsed_html).to include("<a")
    end
  end

  describe "#add_control_class_to_codeblock" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).add_control_class_to_codeblock.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").add_control_class_to_codeblock.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").add_control_class_to_codeblock
      expect(html_parser).to be_a described_class
    end

    context "when the highlight class is present" do
      it "adds the control panel" do
        html = "<div class='highlight'>Hello world!</div>"
        parsed_html = described_class.new(html).add_control_class_to_codeblock.html
        expect(parsed_html).to include("js-code-highlight")
      end
    end

    context "when the highlight class is not present" do
      it "doesn't add the control panel" do
        html = "<div>Hello world!</div>"
        parsed_html = described_class.new(html).add_control_class_to_codeblock.html
        expect(parsed_html).not_to include("js-code-highlight")
      end
    end
  end

  describe "#add_control_panel_to_codeblock" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).add_control_panel_to_codeblock.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").add_control_panel_to_codeblock.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").add_control_panel_to_codeblock
      expect(html_parser).to be_a described_class
    end

    context "when the highlight class is present" do
      it "adds the control panel" do
        html = "<div class='highlight'>Hello world!</div>"
        parsed_html = described_class.new(html).add_control_panel_to_codeblock.html
        expect(parsed_html).to include("highlight__panel", "js-actions-panel")
      end
    end

    context "when the highlight class is not present" do
      it "doesn't add the control panel" do
        html = "<div>Hello world!</div>"
        parsed_html = described_class.new(html).add_control_panel_to_codeblock.html
        expect(parsed_html).not_to include("highlight__panel", "js-actions-panel")
      end
    end
  end

  describe "#add_fullscreen_button_to_panel" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).add_fullscreen_button_to_panel.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").add_fullscreen_button_to_panel.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").add_fullscreen_button_to_panel
      expect(html_parser).to be_a described_class
    end

    it "adds the fullscreen button" do
      html = "<div class='highlight__panel'>Hello World</div>"
      parsed_html = described_class.new(html).add_fullscreen_button_to_panel.html
      expect(parsed_html).to include("Enter fullscreen mode")
    end
  end

  describe "#wrap_all_tables" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).wrap_all_tables.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").wrap_all_tables.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").wrap_all_tables
      expect(html_parser).to be_a described_class
    end

    it "wraps all tables" do
      html = "<table><tr><th>Header</th></tr><tr><td>Data</td></tr></table>"
      parsed_html = described_class.new(html).wrap_all_tables.html
      expect(parsed_html).to include("table-wrapper-paragraph")
    end
  end

  describe "#remove_empty_paragraphs" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).remove_empty_paragraphs.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").remove_empty_paragraphs.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").remove_empty_paragraphs
      expect(html_parser).to be_a described_class
    end

    context "when a paragraph is empty" do
      it "deletes the paragraph" do
        html = "<p></p>"
        parsed_html = described_class.new(html).remove_empty_paragraphs.html
        expect(parsed_html).not_to include("<p>")
      end
    end

    context "when a paragraph is not empty" do
      it "doesn't delete the paragraph" do
        html = "<p>Hello World!</p>"
        parsed_html = described_class.new(html).remove_empty_paragraphs.html
        expect(parsed_html).to eq html
      end
    end
  end

  describe "#escape_colon_emojis_in_codeblock" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).escape_colon_emojis_in_codeblock.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").escape_colon_emojis_in_codeblock.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").escape_colon_emojis_in_codeblock
      expect(html_parser).to be_a described_class
    end

    context "when a colon emoji is used" do
      it "doesn't change text in codeblock" do
        html = "<span>:o:<code>:o:</code>:o:<code>:o:</code>:o:<span>:o:</span>:o:</span>"
        parsed_html = described_class.new(html).escape_colon_emojis_in_codeblock.html
        expect(parsed_html).to include("<span>⭕<code>:o:</code>⭕<code>:o:</code>⭕<span>⭕</span>⭕</span>")
      end
    end
  end

  describe "#unescape_raw_tag_in_codeblocks" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).unescape_raw_tag_in_codeblocks.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").unescape_raw_tag_in_codeblocks.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").unescape_raw_tag_in_codeblocks
      expect(html_parser).to be_a described_class
    end

    it "escapes the `raw` Liquid tag in codeblocks" do
      code_block = "```\n{% raw %}some text{% endraw %}\n```"
      parsed_html = described_class.new(code_block).unescape_raw_tag_in_codeblocks.html
      expect(parsed_html).to include("{% raw %}", "{% endraw %}")
    end

    it "does not render the escaped dashes when using a `raw` Liquid tag in codeblocks with syntax highlighting" do
      code_block = "```js\n{% raw %}some text{% endraw %}\n```"
      parsed_html = described_class.new(code_block).unescape_raw_tag_in_codeblocks.html
      expect(parsed_html).not_to include("----")
    end

    it "does not remove the non-'raw tag related' four dashes" do
      code_block = "```\n----\n```"
      parsed_html = described_class.new(code_block).unescape_raw_tag_in_codeblocks.html
      expect(parsed_html).to include("----")
    end

    it "escapes the `raw` Liquid tag in codespans" do
      code_block = "``{% raw %}some text{% endraw %}``"
      parsed_html = described_class.new(code_block).unescape_raw_tag_in_codeblocks.html
      expect(parsed_html).to include("{% raw %}", "{% endraw %}")
    end

    it "escapes the `raw` Liquid tag in inline code" do
      code_block = "`{% raw %}some text{% endraw %}`"
      parsed_html = described_class.new(code_block).unescape_raw_tag_in_codeblocks.html
      expect(parsed_html).to include("{% raw %}", "{% endraw %}")
    end
  end

  describe "#wrap_all_figures_with_tags" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).wrap_all_figures_with_tags.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").wrap_all_figures_with_tags.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").wrap_all_figures_with_tags
      expect(html_parser).to be_a described_class
    end

    it "wraps figcaptions with figures" do
      html = "<p>case: </p><p>Statement</p>\n<figcaption>A fig</figcaption>"
      parsed_html = described_class.new(html).wrap_all_figures_with_tags.html
      expect(parsed_html).to include("figure")
    end

    it "does not wrap figcaptions already in figures" do
      html = "<figure><p>Statement</p>\n<figcaption>A fig</figcaption></figure>"
      parsed_html = described_class.new(html).wrap_all_figures_with_tags.html
      expect(parsed_html).to eq(html)
    end

    it "does not wrap figcaptions without predecessors" do
      html = "<figcaption>A fig</figcaption>"
      parsed_html = described_class.new(html).wrap_all_figures_with_tags.html
      expect(parsed_html).to eq(html)
    end
  end

  describe "#wrap_mentions_with_links" do
    let(:user) { build_stubbed(:user) }

    before { allow(User).to receive(:find_by).with(username: user.username).and_return(user) }

    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).wrap_mentions_with_links.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").wrap_mentions_with_links.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").wrap_mentions_with_links
      expect(html_parser).to be_a described_class
    end

    it "links mentions" do
      html = "@#{user.username}"
      parsed_html = described_class.new(html).wrap_mentions_with_links.html
      expect(parsed_html).to include("<a")
    end
  end

  describe "#parse_emojis" do
    context "when html is nil" do
      it "doesn't raise an error" do
        expect { described_class.new(nil).parse_emojis.html }.not_to raise_error
      end
    end

    context "when html is empty" do
      it "doesn't raise an error" do
        expect { described_class.new("").parse_emojis.html }.not_to raise_error
      end
    end

    it "returns an instance of Html::Parser" do
      html_parser = described_class.new("<div>Hello World</div>").parse_emojis
      expect(html_parser).to be_a described_class
    end

    # rubocop:disable Rails/DynamicFindBy
    it "converts emoji names wrapped in colons into unicode" do
      joy_emoji_unicode = Emoji.find_by_alias("joy").raw
      parsed_html = described_class.new(":joy:").parse_emojis.html
      expect(parsed_html).to include(joy_emoji_unicode)
    end

    it "converts disability emojis as well", :aggregate_failures do
      disability_emojis = %w[
        guide_dog service_dog person_with_probing_cane man_with_probing_cane woman_with_probing_cane probing_cane
        person_in_motorized_wheelchair man_in_motorized_wheelchair woman_in_motorized_wheelchair
        person_in_manual_wheelchair man_in_manual_wheelchair woman_in_manual_wheelchair manual_wheelchair
        motorized_wheelchair wheelchair
      ]

      disability_emojis.each do |emoji|
        unicode = Emoji.find_by_alias(emoji).raw
        parsed_html = described_class.new(":#{emoji}:").parse_emojis.html
        expect(parsed_html).to include(unicode)
      end
    end

    it "leaves original text between colons when no emoji is found" do
      emoji_text = ":no_one_will_ever_create_an_emoji_with_this_alias:"
      parsed_html = described_class.new(emoji_text).parse_emojis.html
      expect(parsed_html).to include(emoji_text)
    end
    # rubocop:enable Rails/DynamicFindBy
  end
end
