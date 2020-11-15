require "rails_helper"

RSpec.describe DetailsTag, type: :liquid_tag do
  describe "#render" do
    let(:summary) { "Click to see the answer!" }
    let(:content) do
      "The answer is Forem!\n<br>
       \n<iframe\n  width=\"710\"\n  height=\"399\"\n  src=\"https://www.youtube.com/embed/3xTiHxHDb4U\"
       \n  allowfullscreen\n  loading=\"lazy\">\n</iframe>\n<br>\n"
    end

    def generate_details_liquid(summary, content)
      Liquid::Template.register_tag("details", described_class)
      Liquid::Template.parse("{% details #{summary} %} #{content} {% enddetails %}")
    end

    it "generates proper details div with summary" do
      rendered = generate_details_liquid(summary, content).render
      Approvals.verify(rendered, name: "details_liquid_tag_spec", format: :html)
    end
  end
end
