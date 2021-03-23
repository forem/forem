require "rails_helper"

RSpec.describe JsitorTag, type: :liquid_tag do
  describe "#link" do
    let(:jsitor_link) { "https://jsitor.com/embed/B7FQ5tHbY" }

    xss_links = %w(
      //evil.com/?jsitor.com
      https://jsitor.com.evil.com
      https://jsitor.com/embed/B7FQ5tHbY" onload='alert("xss")'
      https://jsitor.com/embed/B7FQ5tHbY?html&js&css&result&light&https://someevilkanevilsite
      B7FQ5tHbYhttps://someevilkanevilsite
      B7FQ5tHbY?html&js&css&result&light&https://someevilkanevilsite
      B7FQ5tHbY?html&js&css&result&light&" onload='alert("kwagmire")'
    )

    def create_jsitor_liquid_tag(link)
      Liquid::Template.register_tag("jsitor", JsitorTag)
      Liquid::Template.parse("{% jsitor #{link} %}")
    end

    # rubocop:disable Style/StringLiterals
    it "renders jsitor liquid tag" do
      liquid = create_jsitor_liquid_tag(jsitor_link)

      expect(liquid.render).to include('<iframe')
        .and include('src="https://jsitor.com/embed/B7FQ5tHbY"')
    end

    it "parses the link with spaces before and after" do
      link = "   https://jsitor.com/embed/B7FQ5tHbY     "
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include('src="https://jsitor.com/embed/B7FQ5tHbY"')
    end

    it "accepts jsitor link with query params" do
      link = "https://jsitor.com/embed/B7FQ5tHbY?html&css"
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include('src="https://jsitor.com/embed/B7FQ5tHbY?html&amp;css"')
    end

    it "accepts jsitor id" do
      link = "B7FQ5tHbY"
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include("https://jsitor.com/embed/#{link}")
    end

    it "accepts jsitor id with parameters" do
      link = "B7FQ5tHbY&amp;html&amp;css"
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include("https://jsitor.com/embed/#{link}")
    end

    it "accepts jsitor link with hyphen id" do
      link = "https://jsitor.com/embed/2o-syYxmi"
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include(link)
    end

    it "accepts jsitor id with hyphen" do
      link = "2o-syYxmi"
      liquid = create_jsitor_liquid_tag(link)

      expect(liquid.render).to include('<iframe')
        .and include("https://jsitor.com/embed/#{link}")
    end
    # rubocop:enable Style/StringLiterals

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
