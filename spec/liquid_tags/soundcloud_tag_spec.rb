require "rails_helper"
require "nokogiri"

RSpec.describe SoundcloudTag, type: :liquid_tag do
  describe "#link" do
    let(:soundcloud_link) { "https://soundcloud.com/user-261265215/dev-to-review-episode-2" }
    let(:url_segment) { "https://w.soundcloud.com/player/?url" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("soundcloud", SoundcloudTag)
      Liquid::Template.parse("{% soundcloud #{link} %}")
    end

    def extract_iframe_src(rendered_iframe)
      parsed_iframe = Nokogiri.HTML(rendered_iframe)
      iframe_src = parsed_iframe.xpath("//iframe/@src")
      CGI.parse(iframe_src[0].value)
    end

    it "accepts soundcloud link" do
      liquid = generate_new_liquid(soundcloud_link)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include("#{url_segment}=#{soundcloud_link}&auto_play=false")
      # rubocop:enable Style/StringLiterals
    end

    it "rejects invalid soundcloud link" do
      expect do
        generate_new_liquid("invalid_soundcloud_link")
      end.to raise_error(StandardError)
    end
  end
end
