require "rails_helper"

RSpec.describe "AhoyEmailClicks" do
  describe "POST /email_clicks" do
    let(:token) { "test_token" }
    let(:campaign) { "test_campaign" }
    let(:url) { "http://example.com" }
    let(:signature) { AhoyEmail::Utils.signature(token: token, campaign: campaign, url: url) }

    before do
      # Stub the publish method
      allow(AhoyEmail::Utils).to receive(:publish).and_return(true)
    end

    context "with a valid signature" do
      it "publishes a click event and returns http ok" do
        # Stub the publish method to prevent external calls
        controller = an_instance_of(Ahoy::EmailClicksController)
        allow(AhoyEmail::Utils).to receive(:publish).and_return(true)

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature }

        expect(response).to have_http_status(:ok)
        expect(AhoyEmail::Utils).to have_received(:publish)
          .with(:click,
                hash_including(token: token, campaign: campaign, url: url, controller: controller))
      end

      it "Records billboard event if params[:bb] present" do
        bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
        # Stub the publish method to prevent external calls
        controller = an_instance_of(Ahoy::EmailClicksController)
        allow(AhoyEmail::Utils).to receive(:publish).and_return(true)

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature, bb: bb_1.id }

        expect(response).to have_http_status(:ok)
        expect(AhoyEmail::Utils).to have_received(:publish)
          .with(:click,
                hash_including(token: token, campaign: campaign, url: url, controller: controller))
        expect(BillboardEvent.where(billboard_id: bb_1.id, category: "click").size).to be(1)
        expect(bb_1.reload.clicks_count).to be(1)
      end

      it "records feed event if article with url path exists" do
        article = create(:article)
        feed_config = create(:feed_config)
        url = "#{URL.article(article)}?context=digest&fc=#{feed_config.id}"
        signature = AhoyEmail::Utils.signature(token: token, campaign: campaign, url: url)
        controller = an_instance_of(Ahoy::EmailClicksController)
        allow(AhoyEmail::Utils).to receive(:publish).and_return(true)

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature }

        expect(response).to have_http_status(:ok)
        expect(AhoyEmail::Utils).to have_received(:publish)
          .with(:click,
                hash_including(token: token, campaign: campaign, url: url, controller: controller))
        expect(FeedEvent.where(article_id: article.id, category: "click", context_type: "email",
                               feed_config_id: feed_config.id).size).to be(1)
      end

      it "enqueues UpdateUserInterestEmbeddingWorker with weight 0.025 if user and article are present" do
        user = create(:user)
        create(:email_message, user: user, token: token)
        article = create(:article)
        url = URL.article(article)
        signature = AhoyEmail::Utils.signature(token: token, campaign: campaign, url: url)

        allow(AhoyEmail::Utils).to receive(:publish).and_return(true)

        sidekiq_assert_enqueued_with(job: UpdateUserInterestEmbeddingWorker,
                                     args: [user.id, article.id,
                                            Ahoy::EmailClicksController::EMAIL_CLICK_INTEREST_BLEND_FACTOR]) do
          post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature }
        end
      end

      it "updates the user's presence" do
        user = create(:user, last_presence_at: 2.hours.ago)
        create(:email_message, user: user, token: token)

        expect { post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature } }
          .to change { user.reload.last_presence_at }
      end

      it "enqueues a Users::RecordFieldTestEventWorker" do
        user = create(:user)
        create(:email_message, user: user, token: token)

        sidekiq_assert_enqueued_with(job: Users::RecordFieldTestEventWorker,
                                     args: [user.id,
                                            AbExperiment::GoalConversionHandler::USER_CLICKS_EMAIL_LINK_GOAL]) do
          post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: signature }
        end
      end
    end

    # The decorator moved this URL construction out of the AhoyEmail::Processor
    # patch and into Emails::AhoyLinkTracking. What has to survive that move is
    # not a particular string but this controller's willingness to accept it, so
    # build the URL the way a Customer.io email would carry it and put it
    # through the same journey baseTracking.js sends a real click on.
    context "with a URL built by Emails::AhoyLinkDecorator" do
      it "verifies the signature and records the click", :aggregate_failures do
        user = create(:user, last_presence_at: 2.hours.ago)
        create(:email_message, user: user, token: token)
        article = create(:article)
        feed_config = create(:feed_config)
        href = "#{URL.article(article)}?context=digest&fc=#{feed_config.id}"

        decorated = Emails::AhoyLinkDecorator.call(
          { "url" => href }, ahoy_data: { token: token, campaign: campaign }
        ).fetch("url")

        # URLSearchParams decodes once and baseTracking.js calls
        # decodeURIComponent on the result, so "u" reaches us twice-decoded.
        params = Rack::Utils.parse_query(Addressable::URI.parse(decorated).query)

        expect do
          post ahoy_email_clicks_path, params: {
            t: params["t"], c: params["c"], u: CGI.unescape(params["u"]), s: params["s"]
          }
        end.to change { user.reload.last_presence_at }

        expect(response).to have_http_status(:ok)
        expect(FeedEvent.where(article_id: article.id, category: "click", context_type: "email").size).to be(1)
      end

      # The encoding depth only matters when the destination itself contains
      # percent sequences: with a plain URL, an extra or missing unescape is a
      # no-op and a single-encoded "u" would still verify. This is the case that
      # actually pins it.
      it "survives a destination carrying percent-encoded characters" do
        href = "#{URL.url}/search?q=100%25%20ruby&tag=c%2B%2B"

        decorated = Emails::AhoyLinkDecorator.call(
          { "url" => href }, ahoy_data: { token: token, campaign: campaign }
        ).fetch("url")

        params = Rack::Utils.parse_query(Addressable::URI.parse(decorated).query)

        post ahoy_email_clicks_path, params: {
          t: params["t"], c: params["c"], u: CGI.unescape(params["u"]), s: params["s"]
        }

        expect(response).to have_http_status(:ok)
      end

      it "sends the recipient to the original destination, not the tracked URL" do
        href = "#{URL.url}/ben/some-post?context=digest"

        decorated = Emails::AhoyLinkDecorator.call(
          { "url" => href }, ahoy_data: { token: token, campaign: campaign }
        ).fetch("url")

        params = Rack::Utils.parse_query(Addressable::URI.parse(decorated).query)

        expect(CGI.unescape(params["u"])).to eq(href)
        expect(decorated).to start_with("#{URL.url}/ben/some-post?context=digest&")
      end
    end

    context "with an invalid signature" do
      it "returns http forbidden" do
        # Use a clearly invalid signature
        invalid_signature = "invalid"

        post ahoy_email_clicks_path, params: { t: token, c: campaign, u: url, s: invalid_signature }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq("Invalid signature")
        # Ensure publish method was not called
        expect(AhoyEmail::Utils).not_to have_received(:publish)
      end
    end
  end
end
