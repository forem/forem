require "rails_helper"

RSpec.describe NeonTag, type: :liquid_tag do
  it "renders properly" do
    Liquid::Template.register_tag("neon", NeonTag)
    liquid = Liquid::Template.parse("{% neon %}")
    expect(liquid.render).to include('<iframe')
  end
end
