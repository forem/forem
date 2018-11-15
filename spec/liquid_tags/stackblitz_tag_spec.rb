require "rails_helper"

RSpec.describe StackblitzTag, type: :liquid_template do
  describe "#id" do
    let(:stackblitz_id) { "ball-demo" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("stackblitz", StackblitzTag)
      Liquid::Template.parse("{% stackblitz #{id} %}")
    end

    it "accepts stackblitz id" do
      liquid = generate_new_liquid(stackblitz_id)
      expect(liquid.render).to include('<div class="ltag__stackblitz">')
    end

    it "renders iframe" do
      liquid = generate_new_liquid(stackblitz_id)
      expect(liquid.render).to include("<iframe")
    end
  end
end
