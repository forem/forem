require "rails_helper"

RSpec.describe "Podcast Episodes Show Spec" do
  describe "GET podcast episodes show" do
    let(:podcast) { create(:podcast) }
    let!(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
    let(:user) { create(:user) }

    it "renders the correct podcast episode hero, comment form, and metadata", :aggregate_failures do
      get "/#{podcast.slug}/#{podcast_episode.slug}"
      expect(response.body).to include podcast_episode.title

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css(".record")).to be_present
      expect(doc.at_css("form#new_comment")).to be_present
      expect(doc.at_css("#comment_commentable_type")&.[]("value")).to eq("PodcastEpisode")
      expect(doc.at_css("#comment_commentable_id")&.[]("value")).to eq(podcast_episode.id.to_s)

      metadata = JSON.parse(doc.at_css(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(podcast.title)
      expect(metadata["episodeName"]).to eq(podcast_episode.title)
      expect(metadata["podcastImageUrl"]).to include(podcast.image_url)
    end

    it "handles single quotes inside the episode metadata", :aggregate_failures do
      single_quote_episode = create(:podcast_episode, podcast: podcast, title: "What's up doc?!")
      get "/#{podcast.slug}/#{single_quote_episode.slug}"

      doc = Nokogiri::HTML(response.body)
      metadata = JSON.parse(doc.at_css(".podcast-episode-container")["data-meta"])
      expect(metadata["podcastName"]).to eq(podcast.title)
      expect(metadata["episodeName"]).to eq(single_quote_episode.title)
      expect(metadata["podcastImageUrl"]).to include(podcast.image_url)
    end

    it "displays unplayable status when not reachable by https and omits random notices", :aggregate_failures do
      unplayable_episode = create(:podcast_episode, podcast: podcast, https: false)
      get "/#{podcast.slug}/#{unplayable_episode.slug}"
      expect(response.body).to include(I18n.t("views.podcasts.statuses.unplayable"))
      expect(response.body).to include("Click here to download")

      notice_podcast = create(:podcast, status_notice: "Random status notice")
      notice_episode = create(:podcast_episode, podcast: notice_podcast)
      get "/#{notice_podcast.slug}/#{notice_episode.slug}"
      expect(response.body).not_to include("Random status notice")
      expect(response.body).not_to include(I18n.t("views.podcasts.statuses.unplayable"))
      expect(response.body).not_to include("Click here to download")
    end

    it "renders published_at when present" do
      published_episode = create(:podcast_episode, podcast: podcast, published_at: 7.hours.ago)
      get "/#{podcast.slug}/#{published_episode.slug}"
      expect(Nokogiri::HTML(response.body).at_css(".published-at")).to be_present
    end

    it "renders nested comment depth classes", :aggregate_failures do
      root_comment = create(:comment, user_id: user.id, commentable: podcast_episode)
      child_comment = create(:comment, user_id: user.id, commentable: podcast_episode, parent: root_comment)

      get "/#{podcast.slug}/#{podcast_episode.slug}"
      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".comment--deep-0#comment-node-#{root_comment.id}").count).to eq(1)
      expect(doc.css(".comment--deep-1#comment-node-#{child_comment.id}").count).to eq(1)
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
