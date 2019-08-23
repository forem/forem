require "rails_helper"

RSpec.describe KotlinTag, type: :liquid_template do
  describe "#link" do
    # Edit at https://pl.kotl.in/zYp4eGLeP
    let(:kotlin_link) { "https://pl.kotl.in/owreUFFUG?theme=darcula&from=3&to=6&readOnly=true" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("kotlin", KotlinTag)
      Liquid::Template.parse("{% kotlin #{link} %}")
    end

    it "accepts kotlin playground link" do
      liquid = generate_new_liquid(kotlin_link)
      rendered_kotlin_iframe = liquid.render
      Approvals.verify(rendered_kotlin_iframe, name: "kotlin_liquid_tag", format: :html)
    end
  end
end
