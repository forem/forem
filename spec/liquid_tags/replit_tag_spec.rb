require "rails_helper"

RSpec.describe ReplitTag, type: :liquid_tag do
  describe "#id" do
    let(:replit_id) { "@WigWog/PositiveFineOpensource" }
    let(:invalid_replit_id) { "@Cant-Have-Dashes/PositiveFineOpensource" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("replit", ReplitTag)
      Liquid::Template.parse("{% replit #{id} %}")
    end

    it "accepts replit id" do
      liquid = generate_new_liquid(replit_id)
      expect(liquid.render).to include('<div class="ltag__replit">')
    end

    it "renders iframe" do
      liquid = generate_new_liquid(replit_id)
      expect(liquid.render).to include("<iframe")
      expect(liquid.render).to include("https://repl.it/#{replit_id}?lite=true")
    end

    it "raises an error for invalid replit id" do
      expect { generate_new_liquid(invalid_replit_id).render }.to raise_error("Invalid Replit URL or @user/slug")
    end
  end
end
