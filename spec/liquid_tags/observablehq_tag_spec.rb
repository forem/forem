require "rails_helper"

RSpec.describe ObservablehqTag, type: :liquid_template do
  describe "#id" do
    def generate_new_liquid(id)
      Liquid::Template.register_tag("observablehq", ObservablehqTag)
      Liquid::Template.parse("{% observablehq #{id} %}")
    end

    it "accepts only ObservableHQ Notebooks patterns" do
      badid = "fsffsfsf/sfsdfsdfsd"
      expect do
        generate_new_liquid(badid)
      end.to raise_error(StandardError)

      badid = "not a valid url"
      expect do
        generate_new_liquid(badid)
      end.to raise_error(StandardError)

      badid = "@d3"
      expect do
        generate_new_liquid(badid)
      end.to raise_error(StandardError)
    end

    def check(url, expected)
      expect(ObservablehqTag.parse_link(url)).to eq(expected)
    end

    it "parses URL correctly" do
      check("@d3/sortable-bar-chart", "https://observablehq.com/embed/@d3/sortable-bar-chart")
      check("09403b146bada149", "https://observablehq.com/embed/09403b146bada149")
      check("@d3/sortable-bar-chart?cell=viewof+order&cell=chart",
            "https://observablehq.com/embed/@d3/sortable-bar-chart?cell=viewof+order&cell=chart")
    end
  end
end
