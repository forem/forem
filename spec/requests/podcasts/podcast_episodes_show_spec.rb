require "rails_helper"

RSpec.describe "Podcast Episodes Show Spec" do
  describe "GET podcast episodes show" do
    let(:podcast) { create(:podcast) }
    let!(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
    let(:user) { create(:user) }

    it "renders the correct podcast episode" do
      get "/#{podcast.slug}/#{podcast_episode.slug}"
      expect(response.body).to include podcast_episode.title
    end

    it "does not render another podcast's episode if the wrong podcast slug is given" do
      other_podcast = create(:podcast)
      expect do
        get "/#{other_podcast.slug}/#{podcast_episode.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with comments" do
      let!(:spam_comment) do
        create(:comment, commentable: podcast_episode, user: user, score: -1000, body_markdown: "spammer-comment")
      end

      before do
        create(:comment, commentable: podcast_episode, body_markdown: "episode-comment")
        create(:comment, commentable: podcast_episode, user: user, score: -50, body_markdown: "mediocre-comment")
        create(:comment, commentable: podcast_episode, user: user, score: -100, body_markdown: "bad-comment")
      end

      it "displays only good standing comments for signed out", :aggregate_failures do
        get "/#{podcast.slug}/#{podcast_episode.slug}"
        expect(response.body).to include("episode-comment")
        expect(response.body).not_to include("spammer-comment")
        expect(response.body).not_to include("mediocre-comment")
        expect(response.body).not_to include("bad-comment")
      end

      it "displays all comments above > -400 for signed in", :aggregate_failures do
        sign_in user
        get "/#{podcast.slug}/#{podcast_episode.slug}"
        expect(response.body).to include("episode-comment")
        expect(response.body).not_to include("spammer-comment")
        expect(response.body).to include("mediocre-comment")
        expect(response.body).to include("bad-comment")
      end

      it "displays deleted message and children of a spam comment for signed in", :aggregate_failures do
        create(:comment, user: user, parent: spam_comment, commentable: podcast_episode,
                         body_markdown: "child-of-a-spam-comment")
        sign_in user
        get "/#{podcast.slug}/#{podcast_episode.slug}"
        expect(response.body).not_to include("spammer-comment")
        expect(response.body).to include("Comment deleted")
        expect(response.body).to include("child-of-a-spam-comment")
      end

      it "displays a low-quality marker for a low-quality comment" do
        sign_in user
        get "/#{podcast.slug}/#{podcast_episode.slug}"
        expect(response.body).to include("low quality/non-constructive") # for bad-comment
      end
    end
  end
end
