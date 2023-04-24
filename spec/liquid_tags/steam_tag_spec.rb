require "rails_helper"
require "nokogiri"

RSpec.describe SteamTag, type: :liquid_tag do
  describe "#id" do
    def generate_tag(id)
      Liquid::Template.register_tag("Steam", SteamTag)
      Liquid::Template.parse("{% Steam #{id} %}")
    end


    def generate_new_liquid(link)
      Liquid::Template.register_tag("steam", SteamTag)
      Liquid::Template.parse("{% steam #{link} %}")
    end

    def extract_iframe_src(rendered_iframe)
      parsed_iframe = Nokogiri.HTML(rendered_iframe)
      iframe_src = parsed_iframe.xpath("//iframe/@src")
      CGI.parse(iframe_src[0].value)
    end

    it "accepts steam link" do
      liquid = generate_new_liquid(steam_link)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include("#{url_segment}=#{steam_link}&frameborder=false")
      # rubocop:enable Style/StringLiterals
    end

    it "rejects invalid steam link" do
      expect do
        generate_new_liquid("invalid_steam_link")
      end.to raise_error(StandardError)
    end
  end
end

