require "rails_helper"

RSpec.describe "Row and Col liquid tags", type: :liquid_tag do
  before do
    Liquid::Template.register_tag("row", RowTag)
    Liquid::Template.register_tag("col", ColTag)
  end

  def parse(template)
    Liquid::Template.parse(template)
  end

  describe "basic rendering" do
    it "renders a row with two equal columns" do
      result = parse("{% row %}{% col %}Left{% endcol %}{% col %}Right{% endcol %}{% endrow %}").render
      expect(result).to include('class="ltag-row"')
      expect(result).to include('class="ltag-col"')
      expect(result).to include("Left")
      expect(result).to include("Right")
    end

    it "renders a row with three columns" do
      result = parse("{% row %}{% col %}A{% endcol %}{% col %}B{% endcol %}{% col %}C{% endcol %}{% endrow %}").render
      expect(result.scan("ltag-col").size).to eq(3)
    end

    it "renders a single column" do
      result = parse("{% row %}{% col %}Only{% endcol %}{% endrow %}").render
      expect(result.scan("ltag-col").size).to eq(1)
    end
  end

  describe "col span option" do
    it "defaults to span 1 (no span class)" do
      result = parse("{% row %}{% col %}Content{% endcol %}{% endrow %}").render
      expect(result).to include('class="ltag-col"')
      expect(result).not_to include("ltag-col-span")
    end

    it "adds span class for span=2" do
      result = parse("{% row %}{% col span=2 %}Wide{% endcol %}{% col %}Narrow{% endcol %}{% endrow %}").render
      expect(result).to include("ltag-col-span-2")
    end

    it "adds span class for span=3" do
      result = parse("{% row %}{% col span=3 %}Wide{% endcol %}{% col %}Narrow{% endcol %}{% endrow %}").render
      expect(result).to include("ltag-col-span-3")
    end

    it "adds span class for span=4" do
      result = parse("{% row %}{% col span=4 %}Wide{% endcol %}{% col %}Narrow{% endcol %}{% endrow %}").render
      expect(result).to include("ltag-col-span-4")
    end

    it "raises an error for span=0" do
      expect do
        parse("{% row %}{% col span=0 %}Content{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /Span must be between 1 and 4/)
    end

    it "raises an error for span=5" do
      expect do
        parse("{% row %}{% col span=5 %}Content{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /Span must be between 1 and 4/)
    end

    it "raises an error for invalid span option" do
      expect do
        parse("{% row %}{% col foo=bar %}Content{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /Invalid option 'foo=bar' for col tag/)
    end
  end

  describe "col background option" do
    it "adds the default background class" do
      result = parse("{% row %}{% col background=default %}Content{% endcol %}{% endrow %}").render

      expect(result).to include("ltag-col-background-default")
    end

    it "adds the subtle background class" do
      result = parse("{% row %}{% col background=subtle %}Content{% endcol %}{% endrow %}").render

      expect(result).to include("ltag-col-background-subtle")
    end

    it "combines background and span options in either order" do
      first = parse("{% row %}{% col span=2 background=default %}Content{% endcol %}{% endrow %}").render
      second = parse("{% row %}{% col background=subtle span=3 %}Content{% endcol %}{% endrow %}").render

      expect(first).to include("ltag-col-span-2", "ltag-col-background-default")
      expect(second).to include("ltag-col-span-3", "ltag-col-background-subtle")
    end

    it "raises an error for an unsupported background" do
      expect do
        parse("{% row %}{% col background=blue %}Content{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /Background must be one of: default, subtle/)
    end

    it "raises an error for a duplicate option" do
      expect do
        parse("{% row %}{% col background=default background=subtle %}Content{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /Invalid option 'background=subtle' for col tag/)
    end
  end

  describe "row tag validation" do
    it "raises an error if row tag receives arguments" do
      expect do
        parse("{% row cols=3 %}{% col %}A{% endcol %}{% endrow %}")
      end.to raise_error(StandardError, /does not accept any arguments/)
    end
  end

  describe "content rendering" do
    it "preserves HTML content inside columns" do
      result = parse("{% row %}{% col %}<strong>Bold</strong>{% endcol %}{% col %}<em>Italic</em>{% endcol %}{% endrow %}").render
      expect(result).to include("<strong>Bold</strong>")
      expect(result).to include("<em>Italic</em>")
    end

    it "evaluates nested Markdown successfully" do
      result = parse("{% row %}{% col %}#### Welcome to Forem\n\nSoftware that powers millions.{% endcol %}{% endrow %}").render
      expect(result).to match(/<h4[^>]*>/)
      expect(result).to include("Welcome to Forem")
      expect(result).to include("<p>Software that powers millions.</p>")
    end

    it "renders Markdown images inside columns" do
      template = <<~LIQUID
        {% row %}
          {% col background=default %}
          ![Cloud infrastructure](https://example.com/cloud.jpg)

          ### Build on reliable infrastructure
          {% endcol %}
        {% endrow %}
      LIQUID
      result = MarkdownProcessor::Parser.new(template).finalize
      column = Nokogiri::HTML.fragment(result).at_css(".ltag-col")

      expect(column["class"]).to include("ltag-col-background-default")
      expect(column.at_css("img").attributes.slice("src", "alt").transform_values(&:value)).to eq(
        "src" => "https://example.com/cloud.jpg",
        "alt" => "Cloud infrastructure",
      )
      expect(column.at_css("h3").text.squish).to eq("Build on reliable infrastructure")
    end

    it "evaluates Markdown headings in documented indented syntax" do
      markdown = <<~LIQUID
        {% row %}
          {% col %}
          ### Predictable

          Body copy.
          {% endcol %}
        {% endrow %}
      LIQUID

      result = MarkdownProcessor::Parser.new(markdown).finalize
      column = Nokogiri::HTML.fragment(result).at_css(".ltag-col")

      expect(column.at_css("h3").text.strip).to eq("Predictable")
      expect(column.at_css("p").text).to eq("Body copy.")
      expect(column.text).not_to include("###")
    end
  end

  describe "content filtering" do
    it "ignores whitespace and newlines between cols" do
      result = parse("{% row %}\n   {% col %}A{% endcol %}\n  {% col %}B{% endcol %}\n{% endrow %}").render
      expect(result).to include("A")
      expect(result).to include("B")
    end

    it "ignores stray text and comments between cols" do
      result = parse("{% row %} This should disappear {% col %}A{% endcol %} # Note: hi {% endrow %}").render
      expect(result).to include("A")
      expect(result).not_to include("This should disappear")
      expect(result).not_to include("# Note: hi")
    end

    it "ignores other liquid tags between cols" do
      Liquid::Template.register_tag("dummy", Liquid::Tag)
      result = parse("{% row %}{% dummy %}{% col %}A{% endcol %}{% endrow %}").render
      expect(result).to include("A")
    end
  end
end
