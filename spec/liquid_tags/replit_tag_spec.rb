require "rails_helper"

RSpec.describe ReplitTag, type: :liquid_tag do
  describe "#id" do
    let(:replit_id) { "@WigWog/PositiveFineOpensource" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("replit", ReplitTag)
      Liquid::Template.parse("{% replit #{id} %}")
    end

    xit "accepts replit id" do
      liquid = generate_new_liquid(replit_id)
      expect(liquid.render).to include('<div class="ltag__replit">')
    end

    xit "renders iframe" do
      liquid = generate_new_liquid(replit_id)
      expect(liquid.render).to include("<iframe")
    end
  end
end
