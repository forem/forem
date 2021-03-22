require "rails_helper"

RSpec.describe DetailsTag, type: :liquid_tag do
  describe "#render" do
    let(:summary) { "Click to see the answer!" }
    let(:content) { "The answer is Forem!" }

    def generate_details_liquid(summary, content)
      Liquid::Template.register_tag("details", described_class)
      Liquid::Template.parse("{% details #{summary} %} #{content} {% enddetails %}")
    end

    it "generates proper details div with summary" do
      rendered = generate_details_liquid(summary, content).render

      expect(rendered).to include("<details")
      expect(rendered).to include('<summary>Click to see the answer!') # rubocop:disable Style/StringLiterals
    end
  end
end
