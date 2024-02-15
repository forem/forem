# these tests were written to check the cache invalidation after adding spam role to the user
# the cache is invalidated in Comments::CalculateScoreWorker
# actually, the tests succeed if there is at least updating comment updated_at (in Comments::CalculateScoreWorker)

require "rails_helper"

RSpec.describe "ArticlesShow" do
  let(:user) { create(:user, :admin) }
  let(:article) { create(:article, user: user, published: true) }
  let(:user2) { create(:user) }

  let(:cache_store) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
  let(:cache) { Rails.cache }

  before do
    sign_in user
    allow(Rails).to receive(:cache).and_return(cache_store)
  end

  it "busts comments cache" do
    comment = create(:comment, commentable: article, user: user2, body_markdown: "potential-spam-comment")
    get article.path
    expect(response.body).to include("potential-spam-comment")

    sidekiq_perform_enqueued_jobs do
      Moderator::ManageActivityAndRoles.handle_user_roles(
        admin: user,
        user: user2,
        user_params: {
          note_for_current_role: "note",
          user_status: "Spam"
        },
      )
    end

    get article.path
    expect(response.body).not_to include("potential-spam-comment")
  end

  it "busts cache when spam comment is a child and a parent" do
    parent = create(:comment, commentable: article, user: user, body_markdown: "parent-comment")
    comment = create(:comment, commentable: article, user: user2, parent: parent, body_markdown: "potential-spam-comment")
    child = create(:comment, commentable: article, user: user, body_markdown: "child-comment", parent: comment)

    get article.path
    expect(response.body).to include("potential-spam-comment")
    expect(response.body).to include("parent-comment")
    expect(response.body).to include("child-comment")

    sidekiq_perform_enqueued_jobs do
      Moderator::ManageActivityAndRoles.handle_user_roles(
        admin: user,
        user: user2,
        user_params: {
          note_for_current_role: "note",
          user_status: "Spam"
        },
      )
    end

    get article.path
    expect(response.body).not_to include("potential-spam-comment")
  end

end