require "rails_helper"

RSpec.describe SpotifyTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_uri) { "spotify:track:0K1UpnetfCKtcNu37rJmCg" }
    let(:valid_playlist_uri) { "spotify:playlist:37i9dQZF1E36t2Deh8frhL" }
    let(:legacy_playlist_uri) { "spotify:user:spotify:playlist:37i9dQZF1E36t2Deh8frhL" }
    let(:invalid_uri) { "asdfasdf:asdfasdf:asdfasdf" }

    def generate_tag(link)
      Liquid::Template.register_tag("spotify", SpotifyTag)
      Liquid::Template.parse("{% spotify #{link} %}")
    end

    def generate_iframe(type, id, height)
      <<~HTML
        <iframe
          src="https://open.spotify.com/embed/#{type}/#{id}"
          width="100%"
          height="#{height}px"
          frameborder="0"
          scrolling="no"
          allowtransparency="true"
          allow="encrypted-media"
          loading="lazy">
        </iframe>
      HTML
    end

    it "generates the proper iframe if the uri is valid" do
      expect(generate_tag(valid_uri).render).to include(generate_iframe("track", "0K1UpnetfCKtcNu37rJmCg", 80))
    end

    it "does not raise an error if the uri is valid" do
      expect { generate_tag(valid_uri) }.not_to raise_error
    end

    it "does not raise an error if the playlist uri is valid" do
      expect { generate_tag(valid_playlist_uri) }.not_to raise_error
    end

    it "does not raise an error for a legacy playlist URI" do
      expect { generate_tag(legacy_playlist_uri) }.not_to raise_error
    end

    it "generates a playlist iframe for a legacy playlist URI" do
      result = generate_tag(legacy_playlist_uri).render
      expect(result).to include("https://open.spotify.com/embed/playlist/37i9dQZF1E36t2Deh8frhL")
      expect(result).to include('height="380px"')
    end

    context "with a web url" do
      let(:track_id) { "64csu9GsP563GpjaSvU17w" }

      it "embeds a plain track url" do
        result = generate_tag("https://open.spotify.com/track/#{track_id}?si=eaac508fe9394a93").render
        expect(result).to include(generate_iframe("track", track_id, 80))
      end

      it "embeds a url with a locale prefix", :aggregate_failures do
        %w[intl-de intl-pt intl-pt-br].each do |locale|
          result = generate_tag("https://open.spotify.com/#{locale}/track/#{track_id}?si=eaac508fe9394a93").render
          expect(result).to include(generate_iframe("track", track_id, 80))
        end
      end

      it "keeps the content height for a locale prefixed playlist" do
        result = generate_tag("https://open.spotify.com/intl-fr/playlist/37i9dQZF1E36t2Deh8frhL").render
        expect(result).to include(generate_iframe("playlist", "37i9dQZF1E36t2Deh8frhL", 380))
      end

      it "embeds a url copied from an embed code" do
        result = generate_tag("https://open.spotify.com/embed/episode/3fLyjTYjIdHxC0kdKMpbGj?utm_source=generator").render
        expect(result).to include(generate_iframe("episode", "3fLyjTYjIdHxC0kdKMpbGj", 232))
      end

      it "embeds a legacy user playlist url" do
        result = generate_tag("https://open.spotify.com/user/spotify/playlist/37i9dQZF1E36t2Deh8frhL").render
        expect(result).to include(generate_iframe("playlist", "37i9dQZF1E36t2Deh8frhL", 380))
      end

      it "still rejects a url from another host" do
        expect do
          generate_tag("https://example.com/intl-de/track/#{track_id}")
        end.to raise_error(StandardError, "Invalid Spotify URI or URL.")
      end
    end

    it "raises an error if the uri is invalid" do
      message = "Invalid Spotify URI or URL."
      expect do
        generate_tag(invalid_uri)
      end.to raise_error(StandardError, message)
    end
  end
end
