require "rails_helper"

RSpec.describe JsitorTag, type: :liquid_template do
  describe "#link" do
    let(:jsitor_embed_id) { "1QgJVmCam" }

    def create_jsitor_liquid_tag(link)
      Liquid::Template.register_tag("jsitor", JsitorTag)
      Liquid::Template.parse("{% jsitor #{link} %}")
    end

    it "renders jsitor liquid tag" do
      liquid = create_jsitor_liquid_tag(jsitor_embed_id)
      render_jsitor_iframe = liquid.render
      Approvals.verify(render_jsitor_iframe, name: "jsitor_liquid_tag", format: :html)
    end
  end
end
