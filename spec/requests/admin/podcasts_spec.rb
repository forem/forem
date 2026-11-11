require "rails_helper"

RSpec.describe "/admin/content_manager/podcasts" do
  let(:admin) { create(:user, :super_admin) }
  let(:podcast) { create(:podcast, published: false) }
  let(:user) { create(:user) }
  let(:podcast_ownership) { create(:podcast_ownership) }

  before do
    sign_in admin
  end

  describe "GET /admin/content_manager/podcasts" do
    let!(:no_eps_podcast) { create(:podcast, title: Faker::Book.title) }

    before do
      create(:podcast_episode, podcast: podcast)
    end

    it "renders success" do
      get admin_podcasts_path
      expect(response).to be_successful
    end

    it "displays podcasts with and without episodes" do
      get admin_podcasts_path
      expect(response.body).to include(CGI.escapeHTML(no_eps_podcast.title))
      expect(response.body).to include(CGI.escapeHTML(podcast.title))
    end

    it "counts podcasts without a grouped episodes join and preloads owners without N+1 queries" do
      second_owner = create(:user)
      create(:podcast_ownership, podcast: podcast, owner: user)
      create(:podcast_ownership, podcast: no_eps_podcast, owner: second_owner)

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get admin_podcasts_path
      end

      expect(response).to be_successful
      expect(response.body).to include("@#{user.username}", "@#{second_owner.username}")

      grouped_join_queries = queries.grep(/LEFT OUTER JOIN "podcast_episodes".*GROUP BY/i)
      expect(grouped_join_queries).to be_empty

      ownership_queries = queries.grep(/FROM "podcast_ownerships"|JOIN "podcast_ownerships"/i)
      expect(ownership_queries.size).to eq(1)
    end
  end

  describe "GET /admin/content_manager/podcasts/:id/edit" do
    it "loads the podcast and owners without duplicate queries" do
      create(:podcast_ownership, podcast: podcast, owner: user)

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        next if payload[:name] == "SCHEMA" || payload[:cached]

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get edit_admin_podcast_path(podcast)
      end

      expect(response).to be_successful
      expect(response.body).to include("@#{user.username}")

      podcast_find_queries = queries.grep(/SELECT "podcasts"\.\* FROM "podcasts" WHERE "podcasts"\."id" =/i)
      expect(podcast_find_queries.size).to eq(1)

      ownership_queries = queries.grep(/INNER JOIN "podcast_ownerships"/i)
      expect(ownership_queries.size).to eq(1)
    end
  end

  describe "Adding owner" do
    it "adds an owner" do
      expect do
        post add_owner_admin_podcast_path(podcast.id), params: { podcast: { user_id: user.id } }
      end.to change(PodcastOwnership, :count).by(1)
    end

    it "does nothing when adding a non-existent user as owner" do
      post add_owner_admin_podcast_path(podcast.id), params: { podcast: { user_id: user.id + 1 } }
      expect(response).to redirect_to(edit_admin_podcast_path(podcast))
    end
  end

  describe "Updating" do
    let(:update_params) do
      {
        title: "hello",
        feed_url: "https://pod.example.com/rss.rss",
        description: "Description",
        itunes_url: "https://itunes.example.com",
        overcast_url: "https://overcast.example.com",
        android_url: "https://android.example.com",
        soundcloud_url: "https://soundcloud.example.com",
        website_url: "https://example.com",
        twitter_username: "@ThePracticalDev",
        pattern_image: fixture_file_upload("800x600.png", "image/png"),
        main_color_hex: "ffffff",
        image: fixture_file_upload("podcast.png", "image/png"),
        slug: "postcast-test-url",
        reachable: true,
        published: true
      }
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "updates the podcast" do
      put admin_podcast_path(podcast), params: { podcast: update_params }
      podcast.reload
      expect(podcast.title).to eq("hello")
      expect(podcast.feed_url).to eq("https://pod.example.com/rss.rss")
      expect(podcast.description).to eq("Description")
      expect(podcast.itunes_url).to eq("https://itunes.example.com")
      expect(podcast.overcast_url).to eq("https://overcast.example.com")
      expect(podcast.android_url).to eq("https://android.example.com")
      expect(podcast.soundcloud_url).to eq("https://soundcloud.example.com")
      expect(podcast.website_url).to eq("https://example.com")
      expect(podcast.twitter_username).to eq("@ThePracticalDev")
      expect(podcast.main_color_hex).to eq("ffffff")
      expect(podcast.slug).to eq("postcast-test-url")
      expect(podcast.reachable).to be(true)
      expect(podcast.published).to be(true)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it "updates image & pattern_image" do
      expect do
        put admin_podcast_path(podcast), params: { podcast: update_params }
        podcast.reload
      end.to change(podcast, :image) && change(podcast, :pattern_image)
    end

    it "redirects after update" do
      put admin_podcast_path(podcast), params: { podcast: update_params }
      expect(response).to redirect_to(edit_admin_podcast_path(podcast))
    end
  end

  describe "POST /admin/content_manager/podcasts/:id/fetch_podcasts" do
    it "redirects back to index with a notice" do
      post fetch_admin_podcast_path(podcast.id)
      expect(response).to redirect_to(admin_podcasts_path)
      expect(flash[:notice]).to include("Podcast's episodes fetching was scheduled (#{podcast.title}, ##{podcast.id})")
    end

    it "schedules a worker to fetch episodes" do
      sidekiq_assert_enqueued_with(job: Podcasts::GetEpisodesWorker,
                                   args: [{ podcast_id: podcast.id, limit: 5, force_update: false }]) do
        post fetch_admin_podcast_path(podcast.id), params: { limit: "5", force: nil }
      end
    end

    it "schedules a worker without limit and with force" do
      sidekiq_assert_enqueued_with(job: Podcasts::GetEpisodesWorker,
                                   args: [{ podcast_id: podcast.id, force_update: true, limit: nil }]) do
        post fetch_admin_podcast_path(podcast.id), params: { force: "1", limit: "" }
      end
    end
  end
end
