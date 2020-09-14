require "rails_helper"

RSpec.describe CacheBuster, type: :labor do
  let(:cache_buster) { described_class }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }
  let(:organization) { create(:organization) }
  let(:listing) { create(:listing, user_id: user.id) }
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:tag) { create(:tag) }

  describe "#bust_nginx_cache" do
    before do
      # Stub out Fastly since we check for fastly_enabled? before nginx_enabled?
      allow(cache_buster).to receive(:fastly_enabled?).and_return(false)
      allow(cache_buster).to receive(:bust_nginx_cache).and_call_original

      allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_DOMAIN").and_return("localhost:9090")
    end

    context "when nginx is available and openresty is configured" do
      it "can bust an nginx cache" do
        cache_buster.bust("/#{user.username}")
        expect(cache_buster).to have_received(:bust_nginx_cache)
      end
    end

    context "when nginx is unavailable and openresty is configured" do
      before do
        allow(cache_buster).to receive(:bust)
        allow(cache_buster).to receive(:nginx_available?).and_return(false)
      end

      it "does not bust an nginx cache" do
        cache_buster.bust("/#{user.username}")
        expect(cache_buster).not_to have_received(:bust_nginx_cache)
      end
    end

    context "when openresty is not configured" do
      before do
        allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_PROTOCOL").and_return(nil)
        allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_DOMAIN").and_return(nil)
      end

      it "does not bust an nginx cache" do
        cache_buster.bust("/#{user.username}")
        expect(cache_buster).not_to have_received(:bust_nginx_cache)
      end
    end
  end

  describe "#bust_fastly_cache" do
    before do
      allow(cache_buster).to receive(:bust_fastly_cache).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("fake-key")
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("localhost:3000")
    end

    it "can bust a fastly cache when configured" do
      cache_buster.bust_fastly_cache("/#{user.username}")
    end
  end

  describe "#bust_comment" do
    it "busts comment" do
      cache_buster.bust_comment(comment.commentable)
    end

    it "busts podcast episode comment" do
      ep_comment = create(:comment, commentable: podcast_episode)
      cache_buster.bust_comment(ep_comment.commentable)
    end
  end

  describe "#bust_article" do
    it "busts article" do
      cache_buster.bust_article(article)
    end

    it "busts featured article" do
      article.update_columns(featured: true)
      cache_buster.bust_article(article)
    end
  end

  describe "#bust_page" do
    it "busts page + slug " do
      cache_buster.bust_page("SlUg")
    end
  end

  describe "#bust_tag" do
    it "busts tag name + tags" do
      expect { cache_buster.bust_tag(tag) }.not_to raise_error
    end
  end

  describe "#bust_events" do
    it "busts events" do
      cache_buster.bust_events
    end
  end

  describe "#bust_podcast" do
    it "busts podcast" do
      cache_buster.bust_podcast("jsparty/the-story-of-konami-js")
    end
  end

  describe "#bust_organization" do
    before do
      create(:article, organization_id: organization.id)
    end

    it "busts slug + article path" do
      cache_buster.bust_organization(organization, "SlUg")
    end

    it "logs an error from bust_organization" do
      allow(Rails.logger).to receive(:error)
      cache_buster.bust_organization(4, 5)
      expect(Rails.logger).to have_received(:error).once
    end
  end

  describe "#bust_podcast_episode" do
    it "busts podcast episode" do
      cache_buster.bust_podcast_episode(podcast_episode, "/cfp", "-007")
    end

    it "logs an error from bust_podcast_episode" do
      allow(Rails.logger).to receive(:warn)
      allow(cache_buster).to receive(:bust).and_raise(StandardError)
      cache_buster.bust_podcast_episode(podcast_episode, 12, "-007")
      expect(Rails.logger).to have_received(:warn).once
    end
  end

  describe "#bust_listings" do
    it "busts listings" do
      expect { cache_buster.bust_listings(listing) }.not_to raise_error
    end
  end

  describe "#bust_user" do
    it "busts a user" do
      allow(cache_buster).to receive(:bust)
      cache_buster.bust_user(user)
      expect(cache_buster).to have_received(:bust).with("/#{user.username}")
      expect(cache_buster).to have_received(:bust).with("/#{user.username}/comments?i=i")
      expect(cache_buster).to have_received(:bust).with("/feed/#{user.username}")
    end
  end
end
