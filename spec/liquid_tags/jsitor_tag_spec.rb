require "rails_helper"

RSpec.describe JsitorTag, type: :liquid_template do
  describe "#link" do
    let(:jsitor_link) { "https://jsitor.com/embed/1QgJVmCam" }

    xss_links = %w(
      //evil.com/?jsitor.com
      https://jsitor.com.evil.com
      https://jsitor.com/embed/1akInalJH" onload='alert("xss")'
    )

    def create_jsitor_liquid_tag(link)
      Liquid::Template.register_tag("jsitor", JsitorTag)
      Liquid::Template.parse("{% jsitor #{link} %}")
    end

    it "renders jsitor liquid tag" do
      liquid = create_jsitor_liquid_tag(jsitor_link)
      render_jsitor_iframe = liquid.render
      Approvals.verify(render_jsitor_iframe, name: "jsitor_liquid_tag", format: :html)
    end

    it "parses the link with spaces before and after" do
      link = "   https://jsitor.com/embed/1QgJVmCam     "
      expect do
        create_jsitor_liquid_tag(link)
      end.not_to raise_error(StandardError)
    end

    it "doesnt accepts jsitor link with query params" do
      link = "https://jsitor.com/embed/1QgJVmCam/?susi=balyu"
      expect do
        create_jsitor_liquid_tag(link)
      end.to raise_error(StandardError)
    end

    it "doesnt accepts jsitor link with a / at the end" do
      link = "https://jsitor.com/embed/1QgJVmCam/"
      expect do
        create_jsitor_liquid_tag(link)
      end.to raise_error(StandardError)
    end

    it "does not accept invalid links" do
      link = "https://invalidlink.com"
      expect do
        create_jsitor_liquid_tag(link)
      end.to raise_error(StandardError)
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { create_jsitor_liquid_tag(link) }.to raise_error(StandardError)
      end
    end
  end
end
