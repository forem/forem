require "rails_helper"

RSpec.describe InstagramTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id)      { "BXgGcAUjM39" }
    let(:invalid_id)    { "blahblahblahbl" }

    def generate_instagram_tag(id)
      Liquid::Template.register_tag("instagram", InstagramTag)
      Liquid::Template.parse("{% instagram #{id} %}")
    end

    it "checks that the tag is properly parsed" do
      valid_id = "BXgGcAUjM39"
      html = "<div class=\"instagram-position\"> <iframe id=\"instagram-liquid-tag\" src=\"https://www.instagram.com/p/#{valid_id}/embed/captioned\" allowtransparency=\"true\" frameborder=\"0\" data-instgrm-payload-id=\"instagram-media-payload-0\" scrolling=\"no\"> </iframe> <script async defer src=\"https://platform.instagram.com/en_US/embeds.js\"></script> </div>" # rubocop:disable Metrics/LineLength
      expect(generate_instagram_tag(valid_id).render).to eq(html.chomp("\n"))
    end

    it "rejects invalid ids" do
      expect { generate_instagram_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_instagram_tag(valid_id) }.not_to raise_error
    end
  end
end
