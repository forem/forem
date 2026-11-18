require "rails_helper"

RSpec.describe "ArticlesUpdate" do
  let(:organization) { create(:organization) }
  let(:organization2) { create(:organization) }
  let(:user) { create(:user) }
  let(:user_org) do
    create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
    organization
  end
  let(:user2) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:other_article) { create(:article, user: user2) }
  let(:collection) { create(:collection, user: user) }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    elsif name == :unpublished_article
      options[:tag_list] = "" unless options.key?(:tag_list)
    end
    super
  end

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

  it "returns an unprocessable status with invalid params" do
    put "/articles/#{article.id}", params: {
      article: { title: "", body_markdown: "Hello World" },
      format: :json
    }

    expect(response).to have_http_status(:unprocessable_entity)
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

  it "adds, preserves, and removes organization ID when user updates", :aggregate_failures do
    user_org_id = user_org.id
    put "/articles/#{article.id}", params: {
      article: { organization_id: user_org_id }
    }
    expect(article.reload.organization_id).to eq user_org_id

    put "/articles/#{article.id}", params: {
      article: { title: "new_title", body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(article.reload.organization_id).to eq user_org_id

    put "/articles/#{article.id}", params: {
      # use empty string instead of nil to mock article form submission
      article: { organization_id: "" }
    }
    expect(article.reload.organization_id).to be_nil
  end

  it "does not modify the organization ID when updating someone else's article as an admin" do
    create(:organization_membership, user: user2, organization: organization2)
    article.update_columns(organization_id: organization2.id, user_id: user2.id)
    user.add_role(:super_admin)
    put "/articles/#{article.id}", params: {
      article: { post_under_org: true }
    }
    expect(article.reload.organization_id).to be_in(user2.organization_ids)
  end

  it "allows an org admin to manage member co-authors and reassign the author while rejecting outsiders",
     :aggregate_failures do
    admin_org_id = user_org.id
    article.update_columns(organization_id: admin_org_id)
    other_user = create(:user)
    create(:organization_membership, user: other_user, organization: user_org)
    outsider = create(:user)

    put "/articles/#{article.id}", params: { article: { co_author_ids_list: outsider.id.to_s }, format: :json }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(article.reload.co_author_ids).to eq([])

    put "/articles/#{article.id}", params: { article: { user_id: other_user.id } }
    expect(article.reload.user).to eq(other_user)
    expect(article.organization_id).to eq(admin_org_id)

    put "/articles/#{article.id}", params: { article: { co_author_ids_list: user.id.to_s } }
    expect(article.reload.co_author_ids).to eq([user.id])
  end

  describe "co-author invitations" do
    let(:follower) { create(:user) }

    def put_invitees(invitee_ids, on: article)
      put "/articles/#{on.id}", params: { article: { co_author_invitee_ids: invitee_ids } }, as: :json
    end

    before { follower.follow(user) }

    it "ignores the invitee list while the feature is disabled" do
      put_invitees([follower.id])

      expect(article.co_author_invitations).to be_empty
    end

    context "when the feature is enabled" do
      before { FeatureFlag.enable(:co_author_invitations) }

      it "invites listed followers, leaves invitations untouched when omitted, and withdraws dropped invitations",
         :aggregate_failures do
        put_invitees([follower.id])
        expect(article.co_author_invitations.pluck(:user_id)).to eq([follower.id])

        put "/articles/#{article.id}", params: { article: { title: "A new title" } }, as: :json
        expect(article.co_author_invitations.count).to eq(1)

        CoAuthorInvitations::Accept.call(article.co_author_invitations.first)
        put_invitees([])

        expect(article.co_author_invitations.reload).to be_empty
        expect(article.reload.co_author_ids).to eq([])
      end

      it "rejects invalid invitees and ignores the list when edited by a non-author", :aggregate_failures do
        put "/articles/#{article.id}", params: { article: { title: "A new title", co_author_invitee_ids: [user2.id] } },
                                       as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(article.reload.title).not_to eq("A new title")

        follower.follow(user2) # so the invitation itself would be valid
        user.add_role(:super_admin)

        put_invitees([follower.id], on: other_article)

        expect(other_article.co_author_invitations).to be_empty
      end
    end
  end

  it "forbids other users from editing an article unless super_admin", :aggregate_failures do
    expect do
      put "/articles/#{other_article.id}", params: { article: { body_markdown: "hello" } }
    end.to raise_error(Pundit::NotAuthorizedError)

    user.add_role(:super_admin)
    put "/articles/#{other_article.id}", params: { article: { title: "new", body_markdown: "hello" } }
    expect(other_article.reload.title).to eq("new")
  end

  it "archives" do
    put "/articles/#{article.id}", params: {
      article: { archived: true }
    }
    expect(article.archived).to be(false)
  end

  it "creates a new collection, assigns an existing series, and resets when empty series is passed",
     :aggregate_failures do
    expect do
      put "/articles/#{article.id}", params: {
        article: { series: "new slug", body_markdown: "blah" }
      }
    end.to change(Collection, :count).by(1)
    expect(article.reload.collection_id).not_to be_nil

    put "/articles/#{article.id}", params: {
      article: { series: collection.slug, body_markdown: "blah" }
    }
    expect(article.reload.collection_id).to eq(collection.id)

    put "/articles/#{article.id}", params: {
      article: { series: "", body_markdown: "blah" }
    }
    expect(article.reload.collection).to be_nil
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
    allow(EdgeCache::BustUser).to receive(:call)

    sidekiq_perform_enqueued_jobs do
      Notification.send_to_followers(article, "Published")
    end
    expect(article.notifications.size).to eq 1

    put "/articles/#{article.id}", params: {
      article: { body_markdown: article.body_markdown.gsub("published: true", "published: false"), version: "v1" }
    }
    expect(article.notifications.size).to eq 0
    expect(EdgeCache::BustUser).to have_received(:call).with(user)
  end

  it "changes video_thumbnail_url effectively" do
    put "/articles/#{article.id}", params: {
      article: { video_thumbnail_url: "https://i.imgur.com/HPiu7N4.jpg" }
    }
    expect(response).to redirect_to "#{article.path}/edit"
    expect(article.reload.video_thumbnail_url).to include "https://i.imgur.com/HPiu7N4.jpg"
  end

  it "preserves video_source_url when omitted or unsupported and clears it when empty or null",
     :aggregate_failures do
    article.update!(video_source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    expect(article.reload.video).to be_present

    put "/articles/#{article.id}",
        params: { article: { title: "New title" } }.to_json,
        headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(article.reload.video_source_url).to eq("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    expect(article.video).to be_present

    put "/articles/#{article.id}",
        params: { article: { video_source_url: "https://vimeo.com/123456" } }.to_json,
        headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(article.reload.video_source_url).to eq("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    put "/articles/#{article.id}", params: { article: { video_source_url: "" } }
    expect(response).to have_http_status(:ok)
    expect(article.reload.video_source_url).to be_nil
    expect(article.video).to be_nil

    article.update!(video_source_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    put "/articles/#{article.id}",
        params: { article: { video_source_url: nil } }.to_json,
        headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(article.reload.video_source_url).to be_nil
    expect(article.video).to be_nil
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
      draft = create(:unpublished_article, user_id: user.id, published_at: nil)
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
    it "updates published_at when scheduled => scheduled and preserves it when published => published",
       :aggregate_failures do
      published_at = 3.days.from_now.in_time_zone("Asia/Dhaka")
      article.update_columns(published: true, published_at: 1.day.from_now)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{published_at.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"

      put "/articles/#{article.id}", params: { article: { body_markdown: body_markdown } }
      expect(article.reload.published_at).to be_within(1.minute).of(published_at)

      past_published_at = DateTime.parse("2022-05-23 18:00 +0030")
      article.update_columns(published: true, published_at: past_published_at)
      next_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{1.day.from_now.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"

      put "/articles/#{article.id}", params: { article: { body_markdown: next_markdown } }
      expect(article.reload.published_at).to eq(past_published_at)
    end

    it "sets current published_at when draft => published and no published_at specified" do
      draft = create(:article, published: false, user_id: user.id, published_at: nil)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      put "/articles/#{draft.id}", params: { article: { body_markdown: body_markdown } }
      draft.reload
      expect(draft.published_at).to be_within(1.minute).of(Time.current)
    end

    it "sets past published_at on initial publish for exported articles and prevents later changes",
       :aggregate_failures do
      date_was = "2022-05-02 19:00:30 UTC"
      date_new = "2022-08-30 19:00:30 UTC"
      draft = create(:article, published: false, user_id: user.id, published_from_feed: true, published_at: nil)
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \ndate: #{date_was}---\n\nHey this is the article"
      put "/articles/#{draft.id}", params: { article: { body_markdown: body_markdown, version: "v1" } }
      draft.reload
      expect(draft.published).to be true
      expect(draft.published_at).to be_within(1.minute).of(DateTime.parse(date_was))

      updated_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \ndate: #{date_new}---\n\nHey this is the article"
      put "/articles/#{draft.id}", params: { article: { body_markdown: updated_markdown, version: "v1" } }
      expect(draft.reload.published_at).to be_within(1.minute).of(DateTime.parse(date_was))
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

    it "changes the author and preserves published_at for scheduled draft and scheduled published articles",
       :aggregate_failures do
      put "/articles/#{draft.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      expect(draft.reload.user_id).to eq(user.id)

      published_at_was = scheduled_article.published_at
      put "/articles/#{scheduled_article.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      scheduled_article.reload
      expect(scheduled_article.user_id).to eq(user.id)
      expect(scheduled_article.published_at).to be_within(1.second).of(published_at_was)

      # mirrors the original "scheduled article" case: published with a future published_at
      scheduled_article.update_columns(user_id: user2.id, published: true)
      put "/articles/#{scheduled_article.id}", params: {
        article: { user_id: user.id, from_dashboard: true }
      }
      scheduled_article.reload
      expect(scheduled_article.user_id).to eq(user.id)
      expect(scheduled_article.published_at).to be_within(1.second).of(published_at_was)
    end
  end
end
