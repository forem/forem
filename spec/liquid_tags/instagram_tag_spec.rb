require "rails_helper"

RSpec.describe InstagramTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id)      { "BXgGcAUjM39" }
    let(:invalid_id)    { "blahblahblahbl" }

    def generate_instagram_tag(id)
      Liquid::Template.register_tag("instagram", InstagramTag)
      Liquid::Template.parse("{% instagram #{id} %}")
    end

    it "checks that the tag is properly parsed" do
      valid_id = "BXgGcAUjM39"
      liquid = generate_instagram_tag(valid_id)

      expect(liquid.render).to include("<blockquote")
        .and include('class="instagram-media"')
        .and include("https://www.instagram.com/p/#{valid_id}/")
        .and include('src="https://platform.instagram.com/en_US/embeds.js"')
        .and include('<div class="instagram-position">')
    end

    it "checks that a reel is properly parsed and rendered" do
      reel_url = "https://www.instagram.com/reel/BXgGcAUjM39/"
      liquid = generate_instagram_tag(reel_url)
      expect(liquid.render).to include("<blockquote")
        .and include('class="instagram-media"')
        .and include("https://www.instagram.com/reel/BXgGcAUjM39/")
    end

    it "checks that a tv post is properly parsed and rendered" do
      tv_url = "https://www.instagram.com/tv/BXgGcAUjM39/"
      liquid = generate_instagram_tag(tv_url)
      expect(liquid.render).to include("<blockquote")
        .and include('class="instagram-media"')
        .and include("https://www.instagram.com/tv/BXgGcAUjM39/")
    end

    it "checks that a profile is properly parsed and rendered" do
      profile_url = "https://www.instagram.com/instagram/"
      liquid = generate_instagram_tag(profile_url)
      expect(liquid.render).to include("<blockquote")
        .and include('class="instagram-media"')
        .and include("https://www.instagram.com/instagram/")
    end

    it "rejects invalid ids" do
      expect { generate_instagram_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_instagram_tag(valid_id) }.not_to raise_error
    end
  end
end
