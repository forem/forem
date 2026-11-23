require "rails_helper"

RSpec.describe CommentTag, type: :liquid_tag do
  let(:user) { create(:user, name: "TheUser") }
  let(:article) { create(:article) }
  let(:comment) do
    create(:comment, commentable: article, user: user, body_markdown: "TheComment")
  end

  before { Liquid::Template.register_tag("comment", described_class) }

  def generate_comment_tag(id_code)
    Liquid::Template.parse("{% comment #{id_code} %}")
  end

  context "when given valid id_code" do
    it "fetches the target comment and render properly" do
      liquid = generate_comment_tag(comment.id_code_generated)

      expect(liquid.render).to include(comment.body_markdown)
        .and include(user.name)
    end

    it "renders 'Comment not found' message if comment ID does not exist" do
      liquid = generate_comment_tag("nonexistentid")

      expect(liquid.render).to include("Comment not found or has been removed.")
    end
  end

  context "when rendered" do
    let(:rendered_tag) { generate_comment_tag(comment.id_code_generated).render }

    it "shows the comment date" do
      expect(rendered_tag).to include(comment.readable_publish_date)
    end

    it "links the comment date to the comment permalink" do
      expect(rendered_tag).to include(%(href="#{URL.comment(comment)}"))
    end

    it "embeds the comment published date" do
      expect(rendered_tag).to include(comment.decorate.readable_publish_date)
    end
  end

  context "with the legacy 'devcomment'" do
    before do
      Liquid::Template.register_tag("devcomment", described_class)
    end

    it "renders properly" do
      liquid = Liquid::Template.parse("{% devcomment #{comment.id_code_generated} %}")

      expect(liquid.render).to include(comment.body_markdown)
      expect(liquid.render).to include(user.name)
    end
  end

  context "when given invalid id_code" do
    it "raises an error" do
      expect do
        generate_comment_tag("Invalid%ID").render
      end.to raise_error(StandardError, "Invalid Comment ID or URL")
    end
  end

  context "when the comment is not publicly visible" do
    it "renders the missing message for a deleted comment" do
      deleted_comment = create(:comment, commentable: article, user: user, body_markdown: "RemovedBody", deleted: true)
      rendered = generate_comment_tag(deleted_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("RemovedBody")
    end

    it "renders the missing message for a comment hidden by the author" do
      hidden_comment = create(
        :comment,
        commentable: article,
        user: user,
        body_markdown: "HiddenBody",
        hidden_by_commentable_user: true,
      )
      rendered = generate_comment_tag(hidden_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("HiddenBody")
    end

    it "renders the missing message for a comment below the hide score threshold" do
      low_score_comment = create(
        :comment,
        commentable: article,
        user: user,
        body_markdown: "LowScoreBody",
        score: Comment::HIDE_THRESHOLD - 1,
      )
      rendered = generate_comment_tag(low_score_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("LowScoreBody")
    end

    it "renders the missing message for a comment on an unpublished article" do
      draft_article = create(:article, published: true, title: "DraftTitle")
      draft_comment = create(:comment, commentable: draft_article, user: user, body_markdown: "DraftCommentBody")
      draft_article.update_columns(published: false)
      rendered = generate_comment_tag(draft_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("DraftCommentBody")
      expect(rendered).not_to include("DraftTitle")
    end

    it "renders the missing message for a comment on a scheduled article" do
      scheduled_article = create(:article, published: true, published_at: 2.days.from_now, title: "ScheduledTitle")
      scheduled_comment = create(:comment, commentable: scheduled_article, user: user, body_markdown: "ScheduledBody")
      rendered = generate_comment_tag(scheduled_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("ScheduledBody")
    end

    it "renders the missing message for a comment on an unpublished podcast episode" do
      unpublished_podcast = create(:podcast, published: false)
      episode = create(:podcast_episode, podcast: unpublished_podcast)
      episode_comment = create(:comment, commentable: episode, user: user, body_markdown: "EpisodeCommentBody")
      rendered = generate_comment_tag(episode_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("EpisodeCommentBody")
    end

    it "renders the missing message for a comment on an unreachable podcast episode" do
      published_podcast = create(:podcast, published: true)
      unreachable_episode = create(:podcast_episode, podcast: published_podcast, reachable: false)
      episode_comment = create(:comment, commentable: unreachable_episode, user: user,
                                         body_markdown: "UnreachableEpisodeCommentBody")
      rendered = generate_comment_tag(episode_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("UnreachableEpisodeCommentBody")
    end

    it "renders the missing message for an orphaned comment with no commentable" do
      orphan_comment = create(:comment, commentable: article, user: user, body_markdown: "OrphanCommentBody")
      orphan_comment.update_columns(commentable_id: nil, commentable_type: nil)
      rendered = generate_comment_tag(orphan_comment.id_code_generated).render

      expect(rendered).to include("Comment not found or has been removed.")
      expect(rendered).not_to include("OrphanCommentBody")
    end
  end
end
