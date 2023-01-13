require "rails_helper"

RSpec.describe "Podcast Episodes Index Spec" do
  describe "GET podcast episodes index" do
    it "renders page with proper sidebar" do
      get "/pod"
      expect(response.body).to include(I18n.t("views.podcasts.suggest_a_podcast"))
    end

    it "shows reachable podcasts" do
      create(:podcast_episode, title: "SuperMario")
      create(:podcast_episode, reachable: false, title: "I'm unreachable")
      get "/pod"
      expect(response.body).to include("SuperMario")
      expect(response.body).not_to include("unreachable")
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
