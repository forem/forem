require "rails_helper"

RSpec.describe SoundcloudTag, type: :liquid_template do
  describe "#link" do
    let(:soundcloud_link) { "https://soundcloud.com/user-261265215/dev-to-review-episode-2" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("soundcloud", SoundcloudTag)
      Liquid::Template.parse("{% soundcloud #{link} %}")
    end

    it "accepts soundcloud link" do
      liquid = generate_new_liquid(soundcloud_link)
      rendered_soundcloud_iframe = liquid.render
      Approvals.verify(rendered_soundcloud_iframe, name: "soundcloud_liquid_tag", format: :html)
    end

    it "rejects invalid soundcloud link" do
      expect do
        generate_new_liquid("invalid_soundcloud_link")
      end.to raise_error(StandardError)
    end
  end
end
