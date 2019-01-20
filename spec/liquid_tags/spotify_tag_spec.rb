require "rails_helper"

RSpec.describe SpotifyTag, type: :liquid_template do
  describe "#link" do
    let(:valid_uri)     { "spotify:track:0K1UpnetfCKtcNu37rJmCg" }
    let(:invalid_uri)   { "asdfasdf:asdfasdf:asdfasdf" }

    def generate_tag(link)
      Liquid::Template.register_tag("spotify", SpotifyTag)
      Liquid::Template.parse("{% spotify #{link} %}")
    end

    it "does not raise an error if the uri is valid" do
      expect { generate_tag(valid_uri) }.not_to raise_error
    end

    it "raises an error if the uri is invalid" do
      expect { generate_tag(invalid_uri) }.to raise_error(StandardError, "Invalid Spotify Link - Be sure you're using the uri of a specific track, album, artist, playlist, or podcast episode.")
    end
  end
end
