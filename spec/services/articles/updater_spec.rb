require "rails_helper"

RSpec.describe Articles::Updater, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:attributes) { { body_markdown: "sample" } }
  let(:draft) { create(:article, user: user, published: false, published_at: nil) }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    elsif %i[unpublished_article published_article].include?(name)
      options[:tag_list] = "" unless options.key?(:tag_list)
    end
    super
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ENABLE_REFRESH_SEGMENT_WORKERS").and_return("true")
    allow(SegmentedUserRefreshWorker).to receive(:perform_async)
  end

  it "updates an article and returns a decorated success result", :aggregate_failures do
    result = described_class.call(user, article, attributes)
    expect(result.success).to be true
    expect(result.article).to be_a(ArticleDecorator)
    expect(article.reload.body_markdown).to eq("sample")
  end

  it "sets a collection" do
    attributes[:series] = "collection-slug"
    described_class.call(user, article, attributes)
    article.reload
    expect(article.collection).to be_a(Collection)
  end

  it "creates a collection for the user, not admin when updated by admin" do
    admin = create(:user, :super_admin)
    attributes[:series] = "new-slug"
    described_class.call(admin, article, attributes)
    expect(article.reload.collection.user).to eq(article.user)
  end

  context "with organization collections" do
    let(:organization) { create(:organization) }
    let(:org_member) { create(:user) }
    let(:org_article) { create(:article, user: org_member, organization: organization) }

    before do
      create(:organization_membership, user: org_member, organization: organization, type_of_user: "member")
    end

    it "creates an organization collection when series is provided and article is under org" do
      attributes[:series] = "org-series"
      described_class.call(org_member, org_article, attributes)
      collection = org_article.reload.collection
      expect(collection).to be_present
      expect(collection.organization).to eq(organization)
      expect(collection.slug).to eq("org-series")
    end

    it "creates a personal collection when series is provided and article has no org" do
      personal_article = create(:article, user: org_member, organization: nil)
      attributes[:series] = "personal-series"
      described_class.call(org_member, personal_article, attributes)
      collection = personal_article.reload.collection
      expect(collection).to be_present
      expect(collection.organization).to be_nil
      expect(collection.slug).to eq("personal-series")
    end

    it "updates collection when organization_id changes" do
      # Create article with org collection
      org_collection = create(:collection, user: org_member, organization: organization, slug: "org-series")
      org_article.update_column(:collection_id, org_collection.id)

      # Change to different org
      other_org = create(:organization)
      create(:organization_membership, user: org_member, organization: other_org, type_of_user: "member")
      attributes[:organization_id] = other_org.id
      attributes[:series] = "other-org-series"

      described_class.call(org_member, org_article, attributes)
      collection = org_article.reload.collection
      expect(collection.organization).to eq(other_org)
      expect(collection.slug).to eq("other-org-series")
    end

    it "finds existing organization collection regardless of user_id" do
      # Create collection with one user
      original_user = create(:user)
      create(:organization_membership, user: original_user, organization: organization, type_of_user: "member")
      existing_collection = create(:collection, user: original_user, organization: organization, slug: "shared-series")

      # Try to update article with same series using different user in same organization
      different_member = create(:user)
      create(:organization_membership, user: different_member, organization: organization, type_of_user: "member")
      different_article = create(:article, user: different_member, organization: organization)

      attributes[:series] = "shared-series"
      described_class.call(different_member, different_article, attributes)

      # Should find the existing collection, not create a new one
      expect(different_article.reload.collection).to eq(existing_collection)
      expect(Collection.where(slug: "shared-series", organization: organization).count).to eq(1)
    end
  end

  it "sets tags" do
    attributes[:tags] = %w[ruby productivity]
    described_class.call(user, article, attributes)
    article.reload
    expect(article.tags.pluck(:name).sort).to eq(%w[productivity ruby])
  end

  describe "result" do
    it "returns not success when not saved", :aggregate_failures do
      invalid_attributes = { body_markdown: nil }
      result = described_class.call(user, article, invalid_attributes)
      expect(result.success).to be false
      expect(result.article.errors.any?).to be true
    end
  end

  describe "notifications" do
    let(:past_time) { 1.year.ago }
    let(:future_time) { 2.days.from_now }

    context "when an article is updated and published the first time" do
      before { attributes[:published] = true }

      # actually, published_at is set in a model
      it "sets current published_at when publishing from a draft" do
        attributes[:published_at] = nil
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.minute).of(Time.current)
      end

      it "sets the passed published_at when a future published_at is passed" do
        attributes[:published_at] = 1.day.from_now
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.second).of(attributes[:published_at])
      end

      it "allows setting past published_at for exported articles (frontmatter)" do
        draft.update_columns(published_from_feed: true)
        past = 10.days.ago
        published_at = past.strftime("%d/%m/%Y %H:%M %z")
        body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{published_at}\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        frontmatter_attributes = { body_markdown: body_markdown }
        described_class.call(user, draft, frontmatter_attributes)
        expect(draft.published_at).to be_within(1.minute).of(past)
      end
    end

    context "when an article is being updated (published => published)" do
      it "doesn't update published_at and delegates to Mentions::CreateAll to create mentions", :aggregate_failures do
        allow(Mentions::CreateAll).to receive(:call)
        attributes[:published] = true
        article.update_column(:published_at, past_time)

        described_class.call(user, article, attributes)

        expect(article.reload.published_at).to be_within(1.second).of(past_time)
        expect(Mentions::CreateAll).to have_received(:call).with(article)
      end
    end

    context "when an article is being republished" do
      it "doesn't update past published_at even when a new published_at is passed via params or frontmatter",
         :aggregate_failures do
        draft.update_column(:published_at, past_time)
        described_class.call(user, draft, attributes.merge(published: true))
        expect(draft.reload.published).to be true
        expect(draft.published_at).to be_within(1.second).of(past_time)

        draft.update_column(:published, false)
        described_class.call(user, draft, attributes.merge(published: true, published_at: 1.day.from_now))
        expect(draft.reload.published).to be true
        expect(draft.published_at).to be_within(1.second).of(past_time)

        draft.update_column(:published, false)
        published_at = 10.days.from_now.strftime("%d/%m/%Y %H:%M %z")
        body_markdown = "---\ntitle: Title\npublished: false\npublished_at: #{published_at}\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        described_class.call(user, draft, { body_markdown: body_markdown })
        expect(draft.reload.published_at).to be_within(1.second).of(past_time)
      end

      it "preserves future published_at unless a new published_at is passed", :aggregate_failures do
        draft.update_column(:published_at, future_time)
        described_class.call(user, draft, attributes.merge(published: true))
        expect(draft.reload.published).to be true
        expect(draft.published_at).to be_within(1.second).of(future_time)

        draft.update_column(:published, false)
        new_published_at = 1.day.from_now
        described_class.call(user, draft, attributes.merge(published: true, published_at: new_published_at))
        expect(draft.reload.published).to be true
        expect(draft.published_at).to be_within(1.minute).of(new_published_at)
      end

      it "doesn't update published_at for exported articles when published_at is passed via params or frontmatter",
         :aggregate_failures do
        draft.update_columns(published_at: past_time, published_from_feed: true)
        new_time = 10.days.from_now
        described_class.call(user, draft, attributes.merge(published_at: new_time))
        expect(draft.reload.published_at).to be_within(1.second).of(past_time)

        new_pub_at = new_time.strftime("%d/%m/%Y %H:%M %z")
        body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{new_pub_at}\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        described_class.call(user, draft, { body_markdown: body_markdown })
        expect(draft.reload.published_at).to be_within(1.second).of(past_time)
      end
    end

    context "when an article is being unpublished from frontmatter" do
      let(:published_at) { 1.hour.from_now }
      let(:published_at_str) { published_at.strftime("%d/%m/%Y %H:%M %z") }
      let(:f_article) do
        markdown = "---\ntitle: Title\npublished: true\npublished_at: #{published_at_str}\n
description:\ntags: heytag\n---\n\nHey this is the article"
        create(:article, user: user, body_markdown: markdown)
      end

      it "doesn't remove published_at when omitted or passed in frontmatter", :aggregate_failures do
        body_without_date = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        described_class.call(user, f_article, { body_markdown: body_without_date })
        expect(f_article.reload.published_at).to be_within(1.minute).of(published_at)

        f_article.update_column(:published, true)
        body_with_date = "---\ntitle: Title\npublished: false\n
        published_at: #{published_at_str}\ndescription:\ntags: heytag\n---\n\nHey this is the article"
        described_class.call(user, f_article, { body_markdown: body_with_date })
        expect(f_article.reload.published_at).to be_within(1.minute).of(published_at)
      end
    end

    context "when an article is being unpublished" do
      before { attributes[:published] = false }

      it "preserves published_at, skips new notifications/mentions, and removes preexisting notifications",
         :aggregate_failures do
        published_at = 1.day.ago
        article.update_column(:published_at, published_at)
        create(:context_notification, context: article, action: "Published")
        allow(Mentions::CreateAll).to receive(:call)
        allow(Notification).to receive(:remove_all_by_action_without_delay).and_call_original

        expect do
          sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
            described_class.call(user, article, attributes)
          end
        end.to change(ContextNotification, :count).by(-1)

        expect(article.reload.published_at).to be_within(1.second).of(published_at)
        expect(Mentions::CreateAll).not_to have_received(:call).with(article)
        expect(Notification).to have_received(:remove_all_by_action_without_delay).with(
          notifiable_ids: article.id, notifiable_type: "Article", action: "Published",
        )
        expect(Notification).to have_received(:remove_all_by_action_without_delay).with(
          notifiable_ids: article.id, notifiable_type: "Article", action: "CoAuthor",
        )
      end
    end

    context "when an article is updated and remains draft" do
      it "doesn't update published_at" do
        attributes[:published] = false
        described_class.call(user, draft, attributes)
        expect(draft.reload.published_at).to be_nil
      end
    end

    context "when an article is being unpublished and contains comments" do
      let!(:comment) { create(:comment, user_id: user.id, commentable: article) }
      let(:notification) do
        create(:notification, user: user, notifiable_id: comment.id, notifiable_type: "Comment")
      end

      before do
        attributes[:published] = false
        allow(Notification).to receive(:remove_all).and_call_original
      end

      it "removes any preexisting comment notifications but does not delete the comment" do
        described_class.call(user, article, attributes)

        expect(Notification).to have_received(:remove_all).with(
          notifiable_ids: [comment.id], notifiable_type: "Comment",
        )
        expect(article.comments.length).to eq(1)
      end
    end

    context "when an article is being unpublished and contains mentions" do
      let!(:mention) { create(:mention, mentionable: article, user: user) }
      let(:notification) do
        create(:notification, user: user, notifiable_id: mention.id, notifiable_type: "Mention")
      end

      before do
        attributes[:published] = false
        allow(Notification).to receive(:remove_all).and_call_original
      end

      it "removes any preexisting mention notifications but does not delete the mention" do
        described_class.call(user, article, attributes)

        expect(Notification).to have_received(:remove_all).with(
          notifiable_ids: [mention.id], notifiable_type: "Mention",
        )
        expect(article.mentions.length).to eq(1)
      end
    end
  end

  describe "user segment refresh on publish state changes" do
    let(:unpublished) { create(:unpublished_article, user: user) }

    it "refreshes user segments only when transitioning from unpublished to published", :aggregate_failures do
      described_class.call(user, unpublished, { published_at: 5.days.from_now })
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)

      described_class.call(user, unpublished, { published: true })
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(user.id).once

      described_class.call(user, unpublished, { published: false })
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).once
    end
  end

  describe "onboarding checklist" do
    before { allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(true) }

    let(:checklist_user) { create(:user) }
    let(:draft) { create(:article, user: checklist_user, published: false, published_at: nil) }

    it "completes made_first_post only when a draft is published by a user registered within 28 days",
       :aggregate_failures do
      described_class.call(checklist_user, draft, { body_markdown: "updated content" })
      expect(checklist_user.onboarding_checklist.reload.items["made_first_post"]).to be_nil

      described_class.call(checklist_user, draft, { body_markdown: "updated content", published: true })
      expect(checklist_user.onboarding_checklist.reload.items["made_first_post"]).to be_present
    end

    it "does not query or complete made_first_post if the user registered more than 28 days ago" do
      checklist_user.update_column(:registered_at, 29.days.ago)
      allow(checklist_user).to receive(:onboarding_checklist)

      described_class.call(checklist_user, draft, { body_markdown: "updated content", published: true })

      expect(checklist_user).not_to have_received(:onboarding_checklist)
    end
  end
end
