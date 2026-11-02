require "rails_helper"

RSpec.describe "Podcast Episodes Index Spec" do
  describe "GET podcast episodes index" do
    it "renders page with proper sidebar" do
      get "/pod"
      expect(response.body).to include(I18n.t("views.podcasts.suggest_a_podcast"))
    end

    it "shows reachable published episodes with links and published_at", :aggregate_failures do
      episode1 = create(:podcast_episode, title: "SuperMario", published_at: 7.hours.ago)
      episode2 = create(:podcast_episode, published_at: 7.days.ago)
      unpublished_podcast = create(:podcast, reachable: true, published: false)
      unreachable_episode = create(
        :podcast_episode,
        podcast: unpublished_podcast,
        reachable: false,
        title: "I'm unreachable",
      )
      unpublished_episode = create(:podcast_episode, podcast: unpublished_podcast)

      get "/pod"
      doc = Nokogiri::HTML(response.body)
      main_content = doc.at_css("#main-content")

      expect(response.body).to include("SuperMario")
      expect(response.body).not_to include("unreachable")
      expect(main_content.at_css("a[href='#{episode1.path}']")).to be_present
      expect(main_content.at_css("a[href='#{episode2.path}']")).to be_present
      expect(main_content.at_css("a[href='#{unreachable_episode.path}']")).to be_nil
      expect(main_content.at_css("a[href='#{unpublished_episode.path}']")).to be_nil
      expect(main_content.at_css("time.published-at")).to be_present
      expect(main_content.at_css("span.time-ago-indicator-initial-placeholder")).to be_present
    end

    it "shows featured podcasts area if there are any" do
      podcast = create(:podcast, featured: true, published: true)
      create(:podcast_episode, title: "SuperMario", podcast: podcast)
      get "/pod"
      expect(response.body).to include(I18n.t("views.podcasts.featured_shows"))
    end

    it "does not show featured podcasts area if there are not any" do
      get "/pod"
      expect(response.body).not_to include(I18n.t("views.podcasts.featured_shows"))
    end

    it "sets proper surrogate key" do
      pe = create(:podcast_episode)
      get "/pod"
      expect(response.headers["Surrogate-Key"]).to eq("podcast_episodes_all podcast_episodes/#{pe.id}")
    end

    it "redirects /podcasts to /pod" do
      get "/podcasts"
      expect(response.body).to redirect_to(pod_path)
    end
  end
end
