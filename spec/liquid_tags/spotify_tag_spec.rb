require "rails_helper"

RSpec.describe SpotifyTag, type: :liquid_template do
  describe "#link" do
    let(:valid_uri)     { 'spotify:track:0K1UpnetfCKtcNu37rJmCg' }
    let(:invalid_uri)   { 'asdfasdf:asdfasdf:asdfasdf'}
    let(:valid_url)     { 'https://open.spotify.com/track/0K1UpnetfCKtcNu37rJmCg'}
    let(:invalid_url)   { 'https://google.com' }

    def generate_tag(link)
      Liquid::Template.register_tag("spotify", SpotifyTag)
      Liquid::Template.parse("{% spotify #{link} %}")
    end

    context 'when link is a URI' do
      it "does not raise an error if valid" do
        expect { generate_tag(valid_uri) }.not_to raise_error
      end

      it "raises an error if invalid" do
        expect { generate_tag(invalid_uri) }.to raise_error(StandardError, "Invalid Spotify Link - Be sure You're linking to a specific track / album / artist / playlist")
      end
    end

    context 'when link is a URL' do
      it "does not raise an error if valid" do
        expect { generate_tag(valid_url) }.not_to raise_error
      end

      it "raises an error if invalid" do
        expect { generate_tag(invalid_url) }.to raise_error(StandardError, "Invalid Spotify Link - Be sure You're linking to a specific track / album / artist / playlist")
      end
    end
  end
end
