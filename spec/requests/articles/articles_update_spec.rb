require "rails_helper"

RSpec.describe "ArticlesUpdate", type: :request do
  let(:organization) { create(:organization) }
  let(:organization2) { create(:organization) }
  let(:user) { create(:user, :org_admin) }
  let(:user2) do
    user = create(:user)
    create(:organization_membership, user: user, organization: organization2)
    user
  end
  let(:article) { create(:article, user_id: user.id) }
  let(:other_article) { create(:article, user: user2) }
  let(:collection) { create(:collection, user: user) }

  before do
    sign_in user
  end

  it "updates ordinary article with proper params" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(article.reload.title).to eq(new_title)
  end

  it "updates article with front matter params" do
    put "/articles/#{article.id}", params: {
      article: {
        title: "hello",
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo"
      }
    }
    expect(article.reload.edited_at).to be > 5.seconds.ago
    expect(article.reload.title).to eq("hey hey hahuu")
  end

  it "adds organization ID when user updates" do
    user_org_id = user.organizations.first.id
    put "/articles/#{article.id}", params: {
      article: { organization_id: user_org_id }
    }
    expect(article.reload.organization_id).to eq user_org_id
  end

  it "removes organization ID when user updates" do
    article.update_column(:organization_id, user.organizations.first.id)
    put "/articles/#{article.id}", params: {
      # use empty string instead of nil to mock article form submission
      article: { organization_id: "" }
    }
    expect(article.reload.organization_id).to eq nil
  end

  it "does not modify the organization ID when the user neither adds nor removes the org" do
    article.update_column(:organization_id, organization.id)
    put "/articles/#{article.id}", params: {
      article: { title: "new_title", body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(article.reload.organization_id).to eq organization.id
  end

  it "does not modify the organization ID when updating someone else's article as an admin" do
    article.update_columns(organization_id: organization2.id, user_id: user2.id)
    user.add_role(:super_admin)
    put "/articles/#{article.id}", params: {
      article: { post_under_org: true }
    }
    expect(article.reload.organization_id).to be_in(user2.organization_ids)
  end

  it "allows an org admin to assign an org article to another user" do
    admin_org_id = user.organizations.first.id
    article.update_columns(organization_id: admin_org_id)
    other_user = create(:user)
    create(:organization_membership, user_id: other_user.id, organization_id: admin_org_id)

    put "/articles/#{article.id}", params: { article: { user_id: other_user.id } }
    expect(article.reload.user).to eq(other_user)
    expect(article.organization_id).to eq(admin_org_id)
  end

  it "allows super_admin to edit an article" do
    user.add_role(:super_admin)
    put "/articles/#{other_article.id}", params: { article: { title: "new", body_markdown: "hello" } }
    expect(other_article.reload.title).to eq("new")
  end

  it "doesn't allow other user to edit an article" do
    expect do
      put "/articles/#{other_article.id}", params: { article: { body_markdown: "hello" } }
    end.to raise_error(Pundit::NotAuthorizedError)
  end

  it "archives" do
    put "/articles/#{article.id}", params: {
      article: { archived: true }
    }
    expect(article.archived).to eq(false)
  end

  it "updates article collection when new series was passed" do
    expect do
      put "/articles/#{article.id}", params: {
        article: { series: "new slug", body_markdown: "blah" }
      }
    end.to change(Collection, :count).by(1)
    article.reload
    expect(article.collection_id).not_to be_nil
  end

  it "updates article collection when series was passed" do
    put "/articles/#{article.id}", params: {
      article: { series: collection.slug, body_markdown: "blah" }
    }
    article.reload
    expect(article.collection_id).to eq(collection.id)
  end

  it "resets article collection when empty series was passed" do
    article.update_column(:collection_id, collection.id)

    put "/articles/#{article.id}", params: {
      article: { series: "", body_markdown: "blah" }
    }
    article.reload
    expect(article.collection).to eq(nil)
  end

  it "creates a notification job if published the first time" do
    draft = create(:article, published: false, user_id: user.id)
    sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker) do
      put "/articles/#{draft.id}", params: {
        article: { published: true, body_markdown: "blah"  }
      }
    end
  end

  it "does not create a notification job if published the second time" do
    article.update_column(:published, false)
    sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
      put "/articles/#{article.id}", params: {
        article: { published: true, body_markdown: "blah"  }
      }
    end
  end

  it "removes all published notifications if unpublished" do
    user2.follow(user)
    sidekiq_perform_enqueued_jobs do
      Notification.send_to_followers(article, "Published")
    end
    expect(article.notifications.size).to eq 1

    put "/articles/#{article.id}", params: {
      article: { body_markdown: article.body_markdown.gsub("published: true", "published: false") }
    }
    expect(article.notifications.size).to eq 0
  end

  it "changes video_thumbnail_url effectively" do
    put "/articles/#{article.id}", params: {
      article: { video_thumbnail_url: "https://i.imgur.com/HPiu7N4.jpg" }
    }
    expect(response).to redirect_to "#{article.path}/edit"
    expect(article.reload.video_thumbnail_url).to include "https://i.imgur.com/HPiu7N4.jpg"
  end

  it "schedules a dispatching event job" do
    create(:webhook_endpoint, events: %w[article_created article_updated], user: user)
    sidekiq_assert_enqueued_jobs(1, only: Webhook::DispatchEventWorker) do
      put "/articles/#{article.id}", params: {
        article: { title: "new_title", body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
      }
    end
  end
end
