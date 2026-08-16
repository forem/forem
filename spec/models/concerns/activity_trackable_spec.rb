require "rails_helper"

RSpec.describe ActivityTrackable do
  let(:user) { create(:user) }
  let(:events) { [] }

  before do
    allow(Trackable::Registry).to receive(:active_names).and_return([:any])
    allow(Trackable::DispatchWorker).to receive(:perform_async) do |_adapter, name, ids, props, _ts|
      events << { name: name, user_ids: ids, properties: props }
    end
    Settings::General.customerio_cdp_enabled = true
  end

  around { |ex| with_trackable_events { ex.run } }

  # Setting up a subject usually emits events of its own (creating an article
  # to comment on emits article_published), so discard whatever the arrangement
  # produced and return only what the block itself emitted.
  def emitted
    events.clear
    yield
    events
  end

  def names(emitted_events)
    emitted_events.pluck(:name)
  end

  describe "the shared gate" do
    let!(:article) { create(:article) }

    it "emits when the master switch is on" do
      result = emitted { create(:comment, user: user, commentable: article) }

      expect(names(result)).to eq(["comment_created"])
    end

    it "stays silent when customerio_cdp_enabled is off" do
      article
      Settings::General.customerio_cdp_enabled = false

      result = emitted { create(:comment, user: user, commentable: article) }

      expect(result).to be_empty
    end

    it "stays silent for bot actors" do
      bot = create(:user, type_of: :community_bot)

      result = emitted { create(:comment, user: bot, commentable: article) }

      expect(result).to be_empty
    end

    it "stays silent for spam accounts" do
      user.add_role(:spam)

      result = emitted { create(:comment, user: user, commentable: article) }

      expect(result).to be_empty
    end

    it "stays silent for suspended accounts" do
      user.add_role(:suspended)

      result = emitted { create(:comment, user: user, commentable: article) }

      expect(result).to be_empty
    end

    it "keys events to the actor rather than the content author" do
      result = emitted { create(:comment, user: user, commentable: article) }

      expect(result.first[:user_ids]).to eq([user.id])
      expect(user.id).not_to eq(article.user_id)
    end
  end

  describe "Article" do
    it "emits article_published when a published article is created" do
      result = emitted { create(:article, user: user) }

      expect(names(result)).to eq(["article_published"])
    end

    it "stays silent while an article is only a draft" do
      result = emitted { create(:article, user: user, published: false) }

      expect(result).to be_empty
    end

    # published and title both come from the body_markdown front matter, which
    # before_validation re-parses on every save, so assigning them directly is
    # silently reverted. Edit the markdown the way the real editor does.
    it "emits article_published when a draft goes live" do
      article = create(:article, user: user, published: false)

      result = emitted do
        article.update!(body_markdown: article.body_markdown.sub("published: false", "published: true"))
      end

      expect(names(result)).to eq(["article_published"])
    end

    it "emits article_updated when a published article's title changes" do
      article = create(:article, user: user)

      result = emitted do
        article.update!(body_markdown: article.body_markdown.sub(article.title, "A brand new title"))
      end

      expect(names(result)).to eq(["article_updated"])
    end

    it "ignores churn outside TRACKABLE_UPDATE_KEYS" do
      article = create(:article, user: user)

      result = emitted { article.update!(score: 50) }

      expect(result).to be_empty
    end

    it "stays silent when a draft is edited" do
      article = create(:article, user: user, published: false)

      result = emitted do
        article.update!(body_markdown: article.body_markdown.sub(article.title, "Still a draft"))
      end

      expect(result).to be_empty
    end

    it "stays silent when an article is unpublished" do
      article = create(:article, user: user)

      result = emitted do
        article.update!(body_markdown: article.body_markdown.sub("published: true", "published: false"))
      end

      expect(result).to be_empty
    end

    it "stays silent when an article is destroyed" do
      article = create(:article, user: user)

      result = emitted { article.destroy }

      expect(result).to be_empty
    end

    it "ships a curated payload rather than the full row" do
      article = create(:article, user: user)

      expect(article.trackable_payload.keys).to contain_exactly(
        "id", "title", "path", "type_of", "published_at", "tag_list",
        "organization_id", "subforem_id", "user_id"
      )
      expect(article.trackable_payload.keys).to all(be_a(String))
    end

    it "emits article_boosted with the boosted article when a status embeds one" do
      boosted = create(:article)

      result = emitted do
        Article.create!(
          user: user, title: "Great post", type_of: "status",
          published: true, body_url: URL.article(boosted)
        )
      end

      expect(names(result)).to eq(["article_boosted"])
      expect(result.first[:properties]).to include(
        "boosted_article_id" => boosted.id,
        "boosted_article_user_id" => boosted.user_id,
      )
    end

    # A status with no body_url must have a blank (but non-nil) body_markdown:
    # validate_status_post rejects a body, and the length validation rejects nil.
    it "emits article_published for a status that embeds nothing internal" do
      result = emitted do
        Article.create!(
          user: user, title: "Just a thought", type_of: "status",
          published: true, body_markdown: ""
        )
      end

      expect(names(result)).to eq(["article_published"])
    end
  end

  describe "Comment" do
    let!(:article) { create(:article) }

    it "emits comment_created on creation" do
      result = emitted { create(:comment, user: user, commentable: article) }

      expect(names(result)).to eq(["comment_created"])
    end

    it "emits comment_updated when the body changes" do
      comment = create(:comment, user: user, commentable: article)

      result = emitted { comment.update!(body_markdown: "Rewritten entirely") }

      expect(names(result)).to eq(["comment_updated"])
    end

    it "ignores reaction counter churn" do
      comment = create(:comment, user: user, commentable: article)

      result = emitted { comment.update!(score: 42) }

      expect(result).to be_empty
    end

    it "stays silent when a comment is soft deleted" do
      comment = create(:comment, user: user, commentable: article)

      result = emitted { comment.update!(deleted: true) }

      expect(result).to be_empty
    end

    it "stays silent when a comment is destroyed" do
      comment = create(:comment, user: user, commentable: article)

      result = emitted { comment.destroy }

      expect(result).to be_empty
    end

    it "carries the commented-on article and its author in the payload" do
      comment = create(:comment, user: user, commentable: article)

      expect(comment.trackable_payload).to include(
        "commentable_type" => "Article",
        "commentable_id" => article.id,
        "commentable_user_id" => article.user_id,
        "user_id" => user.id,
      )
    end
  end

  describe "Reaction" do
    let!(:article) { create(:article) }

    it "emits article_reacted for a public reaction on an article" do
      result = emitted { create(:reaction, user: user, reactable: article, category: "like") }

      expect(names(result)).to eq(["article_reacted"])
    end

    it "emits article_saved for a readinglist reaction" do
      result = emitted { create(:reading_reaction, user: user, reactable: article) }

      expect(names(result)).to eq(["article_saved"])
    end

    it "emits comment_reacted for a reaction on a comment" do
      comment = create(:comment, commentable: article)

      result = emitted { create(:reaction, user: user, reactable: comment, category: "like") }

      expect(names(result)).to eq(["comment_reacted"])
    end

    # vomit outnumbers every public reaction combined on a typical day, so this
    # exclusion is what keeps the event stream affordable.
    it "stays silent for privileged moderation reactions" do
      trusted = create(:user, :trusted)

      result = emitted do
        create(:vomit_reaction, user: trusted, reactable: article)
        create(:thumbsdown_reaction, user: trusted, reactable: article)
      end

      expect(result).to be_empty
    end

    it "stays silent when a reaction is toggled off" do
      reaction = create(:reaction, user: user, reactable: article, category: "like")

      result = emitted { reaction.destroy }

      expect(result).to be_empty
    end

    it "carries the reacted-on record and its author in the payload" do
      reaction = create(:reaction, user: user, reactable: article, category: "unicorn")

      expect(reaction.trackable_payload).to include(
        "category" => "unicorn",
        "reactable_type" => "Article",
        "reactable_id" => article.id,
        "reactable_user_id" => article.user_id,
        "user_id" => user.id,
      )
    end
  end
end
