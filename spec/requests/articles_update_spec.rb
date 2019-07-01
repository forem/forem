require "rails_helper"

RSpec.describe "ArticlesUpdate", type: :request do
  let(:organization) { create(:organization) }
  let(:organization2) { create(:organization) }
  let(:user) { create(:user, :org_admin) }
  let(:user2) { create(:user, organization_id: organization2.id) }
  let(:article) { create(:article, user_id: user.id) }

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
    expect(article.reload.organization_id).to eq user2.organization_id
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

  it "archives" do
    put "/articles/#{article.id}", params: {
      article: { archived: true }
    }
    expect(article.archived).to eq(false)
  end

  it "creates a notification job if published" do
    article.update_column(:published, false)
    assert_enqueued_with(job: Notifications::NotifiableActionJob) do
      put "/articles/#{article.id}", params: {
        article: { published: true }
      }
    end
  end

  it "removes all published notifications if unpublished" do
    user2.follow(user)
    Notification.send_to_followers_without_delay(article, "Published")
    put "/articles/#{article.id}", params: {
      article: { body_markdown: article.body_markdown.gsub("published: true", "published: false") }
    }
    expect(article.notifications.size).to eq 0
  end
end
