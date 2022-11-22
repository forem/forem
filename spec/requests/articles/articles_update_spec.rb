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
        tag_list: "yo",
        version: "v1"
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
    expect(article.reload.organization_id).to be_nil
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
    expect(article.archived).to be(false)
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
    expect(article.collection).to be_nil
  end

  it "does not create a notification job if published the second time" do
    article.update_column(:published, false)
    sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
      put "/articles/#{article.id}", params: {
        article: { published: true, body_markdown: "blah", version: "v1" }
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
      article: { body_markdown: article.body_markdown.gsub("published: true", "published: false"), version: "v1" }
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

  context "when setting published_at in editor v2" do
    let(:tomorrow) { 1.day.from_now }
    let(:published_at) { "#{tomorrow.strftime('%d.%m.%Y')} 18:00" }
    let(:published_at_date) { tomorrow.strftime("%d.%m.%Y") }
    let(:published_at_time) { "18:00" }
    let(:attributes) do
      { title: "NEW TITLE #{rand(100)}", body_markdown: "Yo ho ho#{rand(100)}",
        published_at_date: published_at_date, published_at_time: published_at_time }
    end

    # scheduled => scheduled
    it "updates published_at from scheduled to scheduled" do
      article.update_column(:published_at, 3.days.from_now)
      attributes[:timezone] = "Europe/Moscow"
      attributes[:published] = true
      put "/articles/#{article.id}", params: { article: attributes }
      article.reload
      published_at_utc = article.published_at.in_time_zone("UTC").strftime("%m/%d/%Y %H:%M")
      expect(published_at_utc).to eq("#{tomorrow.strftime('%m/%d/%Y')} 15:00")
    end

    # scheduled => published immediately
    it "udpates published_at to current when removing published_at date" do
      article.update_column(:published_at, 3.days.from_now)
      attributes.delete :published_at_date
      attributes[:published] = true
      now = Time.current
      put "/articles/#{article.id}", params: { article: attributes }
      article.reload
      expect(article.published_at).to be_within(1.minute).of(now)
    end

    # draft => scheduled
    it "sets published_at according to the timezone when updating draft => scheduled" do
      draft = create(:article, published: false, user_id: user.id, published_at: nil)
      attributes[:published] = true
      attributes[:timezone] = "America/Mexico_City"
      put "/articles/#{draft.id}", params: { article: attributes }
      draft.reload
      published_at_utc = draft.published_at.in_time_zone("UTC").strftime("%m/%d/%Y %H:%M")
      draft.published_at.in_time_zone(attributes[:timezone])
      expected_time = "#{(tomorrow + 1.day).strftime('%m/%d/%Y')} 00:00"
      expect(published_at_utc).to eq(expected_time)
      expect(draft.published).to be true
    end

    it "doesn't update published_at when published => published" do
      published_at = DateTime.parse("2022-01-01 15:00 -0400")
      article.update_column(:published_at, published_at)
      attributes[:timezone] = "Europe/Moscow"
      put "/articles/#{article.id}", params: { article: attributes }
      article.reload
      expect(article.published_at).to eq(published_at)
    end
  end

  context "when setting published_at in editor v1" do
    it "updates published_at from scheduled to scheduled with timezone" do
      published_at = 3.days.from_now.in_time_zone("Asia/Dhaka")
      article.update_columns(published: true, published_at: 1.day.from_now)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{published_at.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"

      put "/articles/#{article.id}", params: { article: { body_markdown: body_markdown } }
      article.reload
      expect(article.published_at).to be_within(1.minute).of(published_at)
    end

    it "doesn't update published_at when published => published" do
      published_at = DateTime.parse("2022-05-23 18:00 +0030")
      article.update_columns(published: true, published_at: published_at)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{1.day.from_now.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"

      put "/articles/#{article.id}", params: { article: { body_markdown: body_markdown } }
      article.reload
      expect(article.published_at).to eq(published_at)
    end

    it "sets current published_at when draft => published and no published_at specified" do
      draft = create(:article, published: false, user_id: user.id, published_at: nil)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      put "/articles/#{draft.id}", params: { article: { body_markdown: body_markdown } }
      draft.reload
      expect(draft.published_at).to be_within(1.minute).of(Time.current)
    end

    it "allows to set past published_at when publishing with date and no published_at for exported articles" do
      date = "2022-05-02 19:00:30 UTC"
      draft = create(:article, published: false, user_id: user.id, published_from_feed: true, published_at: nil)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \ndate: #{date}---\n\nHey this is the article"
      put "/articles/#{draft.id}", params: { article: { body_markdown: body_markdown, version: "v1" } }
      draft.reload
      expect(draft.published).to be true
      expect(draft.published_at).to be_within(1.minute).of(DateTime.parse(date))
    end

    it "doesn't allow changing published_at when updating a published article published_from_feed" do
      date_was = "2022-05-02 19:00:30 UTC"
      date_new = "2022-08-30 19:00:30 UTC"
      article = create(:article, :past, published: true, user_id: user.id,
                                        published_from_feed: true, past_published_at: DateTime.parse(date_was))
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \ndate: #{date_new}---\n\nHey this is the article"
      put "/articles/#{article.id}", params: { article: { body_markdown: body_markdown, version: "v1" } }
      article.reload
      expect(article.published_at).to be_within(1.minute).of(DateTime.parse(date_was))
    end
  end

  context "when changing an author inside an organization" do
    before do
      user.add_role(:admin)
      user.organization_memberships.create(organization: organization, type_of_user: "admin")
    end

    let(:draft) { create(:article, user: user2, published: false, organization: organization) }
    let(:scheduled_article) do
      create(:article, user: user2, published_at: 2.days.from_now, published: false, organization: organization)
    end

    it "changes an author" do
      put "/articles/#{draft.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      draft.reload
      expect(draft.user_id).to eq(user.id)
    end

    it "doesn't remove the published_at when changing author for a scheduled draft article" do
      published_at_was = scheduled_article.published_at
      put "/articles/#{scheduled_article.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      scheduled_article.reload
      expect(scheduled_article.user_id).to eq(user.id)
      expect(scheduled_article.published_at).to be_within(1.second).of(published_at_was)
    end

    it "doesn't remove published_at when changing author for a scheduled article" do
      scheduled_article.update_column(:published, true)

      published_at_was = scheduled_article.published_at
      put "/articles/#{scheduled_article.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      scheduled_article.reload
      expect(scheduled_article.user_id).to eq(user.id)
      expect(scheduled_article.published_at).to be_within(1.second).of(published_at_was)
    end
  end
end
