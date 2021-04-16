require "rails_helper"

RSpec.describe JsFiddleTag, type: :liquid_tag do
  describe "#link" do
    let(:jsfiddle_link) { "http://jsfiddle.net/link2twenty/v2kx9jcd" }
    let(:jsfiddle_link_with_custom_tabs) { "http://jsfiddle.net/link2twenty/v2kx9jcd result,html,css" }

    xss_links = %w(
      //evil.com/?jsfiddle.net
      https://jsfiddle.net.evil.com
      https://jsfiddle.net/some_username/pen/" onload='alert("xss")'
    )

    def generate_new_liquid(link)
      Liquid::Template.register_tag("jsfiddle", JsFiddleTag)
      Liquid::Template.parse("{% jsfiddle #{link} %}")
    end

    it "accepts jsfiddle link" do
      liquid = generate_new_liquid(jsfiddle_link)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include('src="http://jsfiddle.net/link2twenty/v2kx9jcd/embedded//dark"')
      # rubocop:enable Style/StringLiterals
    end

    it "accepts jsfiddle link with a / at the end" do
      jsfiddle_link = "http://jsfiddle.net/link2twenty/v2kx9jcd/"
      expect do
        generate_new_liquid(jsfiddle_link)
      end.not_to raise_error
    end

    it "rejects invalid jsfiddle link" do
      expect do
        generate_new_liquid("invalid_jsfiddle_link")
      end.to raise_error(StandardError)
    end

    it "accepts jsfiddle link with a custom-tab parameter" do
      expect do
        generate_new_liquid(jsfiddle_link_with_custom_tabs)
      end.not_to raise_error
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
