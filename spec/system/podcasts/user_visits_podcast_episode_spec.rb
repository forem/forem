require "rails_helper"

RSpec.describe "User visits podcast show page", type: :system do
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }
  let(:single_quote_episode) { create(:podcast_episode, title: "What's up doc?!") }

  xit "they see the content of the hero", js: true, percy: true, retry: 3 do
    visit podcast_episode.path.to_s

    Percy.snapshot(page, name: "Podcast: /:podcast_slug/:episode_slug renders")

    expect(page).to have_text(podcast_episode.title)
    expect(page).to have_css ".record"
    expect(page).not_to have_css ".published-at"
  end

  xit "see the new comment box on the page" do
    visit podcast_episode.path.to_s
    expect(page).to have_css "form#new_comment"
    expect(find("#comment_commentable_type", visible: :hidden).value).to eq("PodcastEpisode")
    expect(find("#comment_commentable_id", visible: :hidden).value).to eq(podcast_episode.id.to_s)
  end

  context "when mobile apps read the podcast episode metadata" do
    xit "renders the Episode & Podcast data" do
      visit podcast_episode.path.to_s
      metadata = JSON.parse(find(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(podcast.title)
      expect(metadata["episodeName"]).to eq(podcast_episode.title)
      expect(metadata["podcastImageUrl"]).to include(podcast.image_url)
    end

    xit "doesn't break with single quotes inside the metadata" do
      visit single_quote_episode.path.to_s
      metadata = JSON.parse(find(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(single_quote_episode.podcast.title)
      expect(metadata["episodeName"]).to eq(single_quote_episode.title)
      expect(metadata["podcastImageUrl"]).to include(single_quote_episode.podcast.image_url)
    end
  end

  context "when episode may not be playable" do
    xit "displays status when episode is not reachable by https", js: true, percy: true do
      podcast_episode = create(:podcast_episode, https: false)
      visit podcast_episode.path.to_s

      Percy.snapshot(page, name: "Podcast: /:podcast_slug/:episode_slug renders when not reachable by https")

      expect(page).to have_text(I18n.t("podcasts.statuses.unplayable"))
      expect(page).to have_text("Click here to download")
    end
  end

  context "when podcast has another status_notice (just in case)" do
    let(:podcast) { create(:podcast, status_notice: "Random status notice") }
    let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }

    xit "doesn't display status_notice" do
      visit podcast_episode.path.to_s
      expect(page).not_to have_text("Random status notice")
      expect(page).not_to have_text(I18n.t("podcasts.statuses.unplayable"))
      expect(page).not_to have_text("Click here to download")
    end
  end

  context "when podcast has publish_at field" do
    let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id, published_at: 7.hours.ago) }

    xit "sees published at" do
      visit podcast_episode.path.to_s
      expect(page).to have_css ".published-at"
    end
  end

  context "when there are existing comments" do
    let(:user) { create(:user) }
    let(:comment) { create(:comment, user_id: user.id, commentable: podcast_episode) }
    let!(:comment2) { create(:comment, user_id: user.id, commentable: podcast_episode, parent: comment) }

    xit "sees the comments", js: true, percy: true do
      visit podcast_episode.path.to_s

      Percy.snapshot(page, name: "Podcast: /:podcast_slug/:episode_slug renders with comments")

      expect(page).to have_selector(".comment-deep-0#comment-node-#{comment.id}", visible: :visible, count: 1)
      expect(page).to have_selector(".comment-deep-1#comment-node-#{comment2.id}", visible: :visible, count: 1)
    end
  end
end
