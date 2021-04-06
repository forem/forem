require "rails_helper"

RSpec.describe "viewing podcast comments", type: :system, js: true do
  let(:user) { create(:user) }
  let(:podcast) { create(:podcast, creator: user) }
  let(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
  let(:comment) { create(:comment, commentable: podcast_episode, user: user) }

  before do
    sign_in user
    visit "/#{podcast.slug}/#{podcast_episode.slug}/comments"
  end

  it "renders comment" do
    # TODO: this spec is broken
    expect(page).to have_content(comment.body_html)
  end
end
