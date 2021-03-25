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

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include('id="instagram-liquid-tag"')
        .and include("https://www.instagram.com/p/#{valid_id}/embed/captioned")
        .and include('src="https://platform.instagram.com/en_US/embeds.js"')
        .and include('<div class="instagram-position">')
      # rubocop:enable Style/StringLiterals
    end

    it "rejects invalid ids" do
      expect { generate_instagram_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_instagram_tag(valid_id) }.not_to raise_error
    end
  end
end
