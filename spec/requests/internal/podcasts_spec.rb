require "rails_helper"

RSpec.describe "/internal/podcasts", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:podcast) { create(:podcast) }
  let(:user) { create(:user) }

  before do
    sign_in admin
  end

  describe "GET /internal/podcasts" do
    let!(:no_eps_podcast) { create(:podcast, title: Faker::Book.title) }

    before do
      create(:podcast_episode, podcast: podcast)
      user.add_role(:podcast_admin, Podcast.order(Arel.sql("RANDOM()")).first)
    end

    it "renders success" do
      get internal_podcasts_path
      expect(response).to be_successful
    end

    it "displays podcasts with and without episodes" do
      get internal_podcasts_path
      expect(response.body).to include(CGI.escapeHTML(no_eps_podcast.title))
      expect(response.body).to include(CGI.escapeHTML(podcast.title))
    end
  end

  describe "Adding admin" do
    it "adds an admin" do
      expect do
        post add_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id } }
      end.to change(Role, :count).by(1)
      user.reload
      expect(user.has_role?(:podcast_admin, podcast)).to be true
    end

    it "does nothing when adding an admin for non-existent user" do
      post add_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id + 1 } }
      expect(response).to redirect_to(edit_internal_podcast_path(podcast))
    end
  end

  describe "Removing admin" do
    it "removes an admin" do
      user.add_role(:podcast_admin, podcast)
      expect do
        delete remove_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id } }
      end.to change(Role, :count).by(-1)
      expect(user.has_role?(:podcast_admin, podcast)).to be false
    end

    it "does nothing when removing an admin for non-existent user" do
      delete remove_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id + 1 } }
      expect(response).to redirect_to(edit_internal_podcast_path(podcast))
    end
  end

  describe "Updating" do
    it "updates" do
      put internal_podcast_path(podcast), params: { podcast: { title: "hello", feed_url: "https://pod.example.com/rss.rss" } }
      podcast.reload
      expect(podcast.title).to eq("hello")
      expect(podcast.feed_url).to eq("https://pod.example.com/rss.rss")
    end

    it "redirects after update" do
      put internal_podcast_path(podcast), params: { podcast: { title: "hello", feed_url: "https://pod.example.com/rss.rss" } }
      expect(response).to redirect_to(internal_podcasts_path)
    end
  end

  describe "POST /internal/podcasts/:id/fetch_podcasts" do
    it "redirects back to index with a notice" do
      post fetch_internal_podcast_path(podcast.id)
      expect(response).to redirect_to(internal_podcasts_path)
      expect(flash[:notice]).to include("Podcast's episodes fetching was scheduled (#{podcast.title}, ##{podcast.id})")
    end

    it "schedules a worker to fetch episodes" do
      sidekiq_assert_enqueued_with(job: Podcasts::GetEpisodesWorker, args: [{ podcast_id: podcast.id, limit: 5, force: false }]) do
        post fetch_internal_podcast_path(podcast.id), params: { limit: "5", force: nil }
      end
    end

    it "schedules a worker without limit and with force" do
      sidekiq_assert_enqueued_with(job: Podcasts::GetEpisodesWorker, args: [{ podcast_id: podcast.id, force: true, limit: nil }]) do
        post fetch_internal_podcast_path(podcast.id), params: { force: "1", limit: "" }
      end
    end
  end
end
