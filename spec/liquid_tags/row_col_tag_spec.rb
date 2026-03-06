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
      end.to raise_error(StandardError, /Span must be between 1 and 4/)
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
  end
end
