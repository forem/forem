require "rails_helper"

RSpec.describe "LiquidEmbeds", vcr: { cassette_name: "twitter_client_status_extended" } do
  describe "get /embeds" do
    let(:path) { liquid_embed_path("tweet", args: 1_018_911_886_862_057_472) }

    it "renders proper tweet" do
      get path
      expect(response.body).to include("ltag__twitter-tweet")
    end

    it "renders proper CSS" do
      get path
      expect(response.body).to include("blockquote.ltag__twitter-tweet")
    end

    it "renders 404 if improper tweet" do
      expect do
        get liquid_embed_path("tweet", args: "improper")
      end.to raise_error(ActionController::RoutingError)
    end

    it "contains base target parent" do
      get path
      expect(response.body).to include('<base target="_parent">')
    end

    it "renders a youtube embed" do
      get liquid_embed_path("youtube", args: "dQw4w9WgXcQ")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://www.youtube.com/embed/dQw4w9WgXcQ")
    end

    it "renders a unified embed tag" do
      get liquid_embed_path("embed", args: "https://youtu.be/dQw4w9WgXcQ")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://www.youtube.com/embed/dQw4w9WgXcQ")
    end

    it "rejects block tags when args contain closing tag delimiters" do
      expect do
        get liquid_embed_path("card", args: "%}<script>alert(1)</script>{% endcard")
      end.to raise_error(ActionController::RoutingError)

      expect do
        get liquid_embed_path("quote", args: 'author="x" %}<img src=x onerror=alert(1)>{% endquote')
      end.to raise_error(ActionController::RoutingError)

      expect do
        get liquid_embed_path("offer", args: "%}<script>alert(1)</script>{% endoffer")
      end.to raise_error(ActionController::RoutingError)
    end

    it "rejects built-in Liquid tags and unexpected tag delimiters in args" do
      expect do
        get liquid_embed_path("raw", args: "%}<script>alert(1)</script>{% endraw")
      end.to raise_error(ActionController::RoutingError)

      expect do
        get liquid_embed_path("tweet", args: "1018911886862057472 %}<script>alert(1)</script>{% endtweet")
      end.to raise_error(ActionController::RoutingError)

      expect do
        get liquid_embed_path("tweet %}<script>alert(1)</script>{%", args: "")
      end.to raise_error(ActionController::RoutingError)
    end

    it "renders 404 for non-Reddit hosts passed to the reddit embed" do
      stub_request(:get, "https://reddit.com.example.com/r/aww/comments/123.json")

      expect do
        get liquid_embed_path("reddit", args: "https://reddit.com.example.com/r/aww/comments/123")
      end.to raise_error(ActionController::RoutingError)

      expect do
        get liquid_embed_path("reddit", args: "https://reddit.com@127.0.0.1/r/aww/comments/123")
      end.to raise_error(ActionController::RoutingError)

      expect(a_request(:get, "https://reddit.com.example.com/r/aww/comments/123.json")).not_to have_been_made
    end
  end
end
