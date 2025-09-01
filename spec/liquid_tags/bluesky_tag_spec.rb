require "rails_helper"

RSpec.describe BlueskyTag, type: :liquid_tag do
  describe "#render" do
    # A valid Bluesky URL (web format)
    let(:valid_url) { "https://bsky.app/profile/did:plc:abcdef12345/post/3ldhpt43zps2g" }
    # A valid Bluesky AT-URI format
    let(:valid_at_uri) { "at://did:plc:abcdef12345/app.bsky.feed.post/3ldhpt43zps2g" }
    # An obviously invalid input that should trigger an error during tag initialization
    let(:invalid_input) { "invalid-input" }

    # Helper method to register and parse the Bluesky tag with the given input.
    def generate_bluesky_tag(input)
      Liquid::Template.register_tag("bluesky", BlueskyTag)
      Liquid::Template.parse("{% bluesky #{input} %}")
    end

    before do
      # Stub the HTTParty.get call to simulate a response from the oEmbed endpoint.
      allow(HTTParty).to receive(:get)
        .and_return({ "html" => "<iframe class=\"bluesky-embed\" src=\"https://example.com/embed\"></iframe>" })
      # Stub ApplicationController.render to simulate the rendering of the partial.
      allow(ApplicationController).to receive(:render)
        .and_return("<div class=\"bluesky-embed\">Embedded Bluesky Post</div>")
    end

    it "renders the Bluesky embed for a valid URL" do
      liquid = generate_bluesky_tag(valid_url)
      rendered = liquid.render

      # Check that the rendered output contains markers from our stubbed partial.
      expect(rendered).to include("bluesky-embed")
      expect(rendered).to include("Embedded Bluesky Post")
    end

    it "renders the Bluesky embed for a valid AT-URI" do
      liquid = generate_bluesky_tag(valid_at_uri)
      rendered = liquid.render

      expect(rendered).to include("bluesky-embed")
      expect(rendered).to include("Embedded Bluesky Post")
    end

    it "rejects invalid inputs" do
      # Since BlueskyTag#initialize calls parse_id_or_url immediately,
      # providing an invalid input should raise a StandardError.
      expect { generate_bluesky_tag(invalid_input) }
        .to raise_error(StandardError, "Invalid Bluesky URL")
    end

    it "accepts a valid URL without raising errors" do
      expect { generate_bluesky_tag(valid_url) }
        .not_to raise_error
    end
  end
end
