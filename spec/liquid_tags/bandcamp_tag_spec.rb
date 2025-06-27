require "rails_helper"

RSpec.describe BandcampTag, type: :liquid_tag do
  describe "#render" do
    let(:album_url_caribou) { "https://caribouband.bandcamp.com/album/our-love" }
    let(:album_id_caribou) { "2555301076" }

    let(:track_url_caribou) { "https://caribouband.bandcamp.com/track/our-love" }
    let(:track_id_caribou_track) { "2467809344" }
    let(:album_id_caribou_for_track) { "2555301076" }

    let(:malformed_bandcamp_url) { "https://bandcamp.com/album_missing_slug" }
    let(:not_bandcamp_url) { "https://example.com/album/some-album" }
    let(:fetch_failure_url) { "https://failartist.bandcamp.com/album/will-not-fetch" }

    def generate_liquid_output(input_string)
      Liquid::Template.register_tag("bandcamp", BandcampTag)
      Liquid::Template.parse("{% bandcamp #{input_string} %}").render
    end

    before do
      allow(HTTParty).to receive(:get).and_call_original

      allow(HTTParty).to receive(:get)
        .with(album_url_caribou, anything)
        .and_return(instance_double(HTTParty::Response, success?: true, code: 200, body: <<~HTML
          <html><head>
            <meta name="bc-page-properties" content='{"item_type":"album","item_id":#{album_id_caribou}}'>
          </head></html>
        HTML
        ))

      allow(HTTParty).to receive(:get)
        .with(track_url_caribou, anything)
        .and_return(instance_double(HTTParty::Response, success?: true, code: 200, body: <<~HTML
          <html><head>
            <meta name="bc-page-properties" content='{"item_type":"track","item_id":#{track_id_caribou_track},"album_id":#{album_id_caribou_for_track}}'>
          </head></html>
        HTML
        ))

      allow(HTTParty).to receive(:get)
        .with(fetch_failure_url, anything)
        .and_return(instance_double(HTTParty::Response, success?: false, code: 404))
    end

    context "with a valid Bandcamp album URL" do
      it "renders the Bandcamp album player iframe" do
        output = generate_liquid_output(album_url_caribou)
        expect(output).to include("<iframe")
        expect(output).to include("src=\"https://bandcamp.com/EmbeddedPlayer/album=#{album_id_caribou}/size=large/artwork=small/tracklist=false/bgcol=ffffff/linkcol=0687f5/transparent=true/\"")
        expect(output).to include("style=\"border: 0; width: 100%; height: 120px;\"")
      end
    end

    context "with a valid Bandcamp track URL" do
      it "renders the Bandcamp track player iframe with album and track ID" do
        output = generate_liquid_output(track_url_caribou)
        expect(output).to include("<iframe")
        expect(output).to include("src=\"https://bandcamp.com/EmbeddedPlayer/album=#{album_id_caribou_for_track}/track=#{track_id_caribou_track}/size=large/artwork=small/tracklist=false/bgcol=ffffff/linkcol=0687f5/transparent=true/\"")
        expect(output).to include("style=\"border: 0; width: 100%; height: 120px;\"")
      end
    end

    context "with an invalid Bandcamp URL format" do
      it "returns an error message" do
        output = generate_liquid_output(malformed_bandcamp_url)
        expect(output).to include("Invalid Bandcamp URL")
      end
    end

    context "with a non-Bandcamp URL" do
      it "returns an error message" do
        output = generate_liquid_output(not_bandcamp_url)
        expect(output).to include("Invalid Bandcamp URL")
      end
    end

    context "when fetching page data fails" do
      it "returns an error message" do
        output = generate_liquid_output(fetch_failure_url)
        expect(output).to include("Could not get sufficient embed data")
      end
    end
  end
end
