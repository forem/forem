# these tests were written to check the cache invalidation after adding spam role to the user
# the cache is invalidated in Comments::CalculateScoreWorker
# actually, the tests succeed if there is at least updating comment updated_at (in Comments::CalculateScoreWorker)

require "rails_helper"

RSpec.describe "ArticleCommentsWithCache" do
  let(:admin) { create(:user, :admin) }
  let(:article) { create(:article, user: admin, published: true) }
  let(:user2) { create(:user) }

  let(:parent) { create(:comment, commentable: article, user: admin, body_markdown: "parent-comment") }

  let(:cache_store) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
  let(:cache) { Rails.cache }

  before do
    allow(Rails).to receive(:cache).and_return(cache_store)
  end

  def assign_spam_role
    sidekiq_perform_enqueued_jobs do
      Moderator::ManageActivityAndRoles.handle_user_roles(
        admin: admin,
        user: user2,
        user_params: {
          note_for_current_role: "note",
          user_status: "Spam"
        },
      )
    end
  end

  describe "GET /:slug (articles)" do
    it "busts comments cache" do
      sign_in admin
      create(:comment, commentable: article, user: user2, body_markdown: "potential-spam-comment")
      get article.path
      expect(response.body).to include("potential-spam-comment")
      assign_spam_role
      get article.path
      expect(response.body).not_to include("potential-spam-comment")
    end

    it "busts cache when spam comment is a child and a parent" do
      sign_in admin

      comment = create(:comment, commentable: article, user: user2, parent: parent,
                                 body_markdown: "potential-spam-comment")
      create(:comment, commentable: article, user: admin, body_markdown: "child-comment", parent: comment)

      get article.path
      expect(response.body).to include("potential-spam-comment")
      expect(response.body).to include("parent-comment")
      expect(response.body).to include("child-comment")

      assign_spam_role

      get article.path
      expect(response.body).not_to include("potential-spam-comment")
    end
  end

  describe "GET /:username/comment/:id_code (root comment path)" do
    it "busts cache for root comment" do
      sign_in user2

      comment = create(:comment, commentable: article, user: user2, parent: parent,
                                 body_markdown: "potential-spam-comment")
      create(:comment, commentable: article, user: admin, body_markdown: "child-comment", parent: comment)

      get parent.path
      expect(response.body).to include("potential-spam-comment")
      expect(response.body).to include("parent-comment")
      expect(response.body).to include("child-comment")

      assign_spam_role

      get parent.path
      expect(response.body).not_to include("potential-spam-comment")
    end
  end
end
