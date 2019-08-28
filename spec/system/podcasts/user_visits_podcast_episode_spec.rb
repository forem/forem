require "rails_helper"

RSpec.describe "User visits podcast show page", type: :system do
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }

  it "they see the content of the hero", retry: 3 do
    visit podcast_episode.path.to_s
    expect(page).to have_text(podcast_episode.title)
    expect(page).to have_css ".record"
  end

  it "see the new comment box on the page" do
    visit podcast_episode.path.to_s
    expect(page).to have_css "form#new_comment"
    expect(find("#comment_commentable_type", visible: false).value).to eq("PodcastEpisode")
    expect(find("#comment_commentable_id", visible: false).value).to eq(podcast_episode.id.to_s)
  end

  context "when episode may not be playable" do
    it "displays status when episode is not reachable by https" do
      podcast_episode = create(:podcast_episode, https: false)
      visit podcast_episode.path.to_s
      expect(page).to have_text(I18n.t("podcasts.statuses.unplayable"))
      expect(page).to have_text("Click here to download")
    end
  end

  context "when podcast has another status_notice (just in case)" do
    let(:podcast) { create(:podcast, status_notice: "Random status notice") }
    let!(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }

    it "doesn't display status_notice" do
      visit podcast_episode.path.to_s
      expect(page).not_to have_text("Random status notice")
      expect(page).not_to have_text(I18n.t("podcasts.statuses.unplayable"))
      expect(page).not_to have_text("Click here to download")
    end
  end

  context "when there're existing comments" do
    let(:user) { create(:user) }
    let(:comment) { create(:comment, user_id: user.id, commentable: podcast_episode) }
    let!(:comment2) { create(:comment, user_id: user.id, commentable: podcast_episode, parent: comment) }

    it "sees the comments", js: true do
      visit podcast_episode.path.to_s
      expect(page).to have_selector(".comment-deep-0#comment-node-#{comment.id}", visible: true, count: 1)
      expect(page).to have_selector(".comment-deep-1#comment-node-#{comment2.id}", visible: true, count: 1)
    end
  end
end
