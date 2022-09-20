require "rails_helper"

RSpec.describe "User visits podcast show page", type: :system, js: true do
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:single_quote_episode) { create(:podcast_episode, title: "What's up doc?!") }

  it "doesn't detect native capabilities from a non-mobile web browser" do
    visit podcast_episode.path.to_s

    result = evaluate_script("window.Forem.Runtime.isNativeIOS('podcast')")
    expect(result).to be false
    result = evaluate_script("window.Forem.Runtime.isNativeAndroid('podcast')")
    expect(result).to be false
  end

  it "they see the content of the hero", :flaky, js: true do
    visit podcast_episode.path.to_s

    expect(page).to have_text(podcast_episode.title)
    expect(page).to have_css ".record"
  end

  it "see the new comment box on the page" do
    visit podcast_episode.path.to_s
    expect(page).to have_css "form#new_comment"
    expect(find("#comment_commentable_type", visible: :hidden).value).to eq("PodcastEpisode")
    expect(find("#comment_commentable_id", visible: :hidden).value).to eq(podcast_episode.id.to_s)
  end

  context "when mobile apps read the podcast episode metadata" do
    it "renders the Episode & Podcast data" do
      visit podcast_episode.path.to_s
      metadata = JSON.parse(find(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(podcast.title)
      expect(metadata["episodeName"]).to eq(podcast_episode.title)
      expect(metadata["podcastImageUrl"]).to include(podcast.image_url)
    end

    it "doesn't break with single quotes inside the metadata" do
      visit single_quote_episode.path.to_s
      metadata = JSON.parse(find(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(single_quote_episode.podcast.title)
      expect(metadata["episodeName"]).to eq(single_quote_episode.title)
      expect(metadata["podcastImageUrl"]).to include(single_quote_episode.podcast.image_url)
    end
  end

  context "when episode may not be playable" do
    it "displays status when episode is not reachable by https", js: true do
      podcast_episode = create(:podcast_episode, https: false)
      visit podcast_episode.path.to_s

      expect(page).to have_text(I18n.t("views.podcasts.statuses.unplayable"))
      expect(page).to have_text("Click here to download")
    end
  end

  context "when podcast has another status_notice (just in case)" do
    let(:podcast) { create(:podcast, status_notice: "Random status notice") }
    let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }

    it "doesn't display status_notice" do
      visit podcast_episode.path.to_s
      expect(page).not_to have_text("Random status notice")
      expect(page).not_to have_text(I18n.t("views.podcasts.statuses.unplayable"))
      expect(page).not_to have_text("Click here to download")
    end
  end

  context "when podcast has publish_at field" do
    let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id, published_at: 7.hours.ago) }

    it "sees published at" do
      visit podcast_episode.path.to_s
      expect(page).to have_css ".published-at"
    end
  end

  context "when there are existing comments" do
    let(:user) { create(:user) }
    let(:comment) { create(:comment, user_id: user.id, commentable: podcast_episode) }
    let!(:comment2) { create(:comment, user_id: user.id, commentable: podcast_episode, parent: comment) }

    it "sees the comments", js: true do
      visit podcast_episode.path.to_s

      expect(page).to have_selector(".comment--deep-0#comment-node-#{comment.id}", visible: :visible, count: 1)
      expect(page).to have_selector(".comment--deep-1#comment-node-#{comment2.id}", visible: :visible, count: 1)
    end
  end
end
