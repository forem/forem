require "rails_helper"

RSpec.describe Articles::Updater, type: :service do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let(:attributes) { { body_markdown: "sample" } }
  let(:draft) { create(:article, user: user, published: false, published_at: nil) }

  it "updates an article" do
    described_class.call(user, article, attributes)
    article.reload
    expect(article.body_markdown).to eq("sample")
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

  it "sets tags" do
    attributes[:tags] = %w[ruby productivity]
    described_class.call(user, article, attributes)
    article.reload
    expect(article.tags.pluck(:name).sort).to eq(%w[productivity ruby])
  end

  describe "result" do
    it "returns success when saved" do
      result = described_class.call(user, article, attributes)
      expect(result.success).to be true
      expect(result.article).to be_a(ArticleDecorator)
    end

    it "returns not success when not saved" do
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
      it "doesn't update published_at" do
        attributes[:published] = true
        article.update_column(:published_at, past_time)
        described_class.call(user, article, attributes)
        article.reload
        expect(article.published_at).to be_within(1.second).of(past_time)
      end

      it "delegates to the Mentions::CreateAll service to create mentions" do
        allow(Mentions::CreateAll).to receive(:call)
        described_class.call(user, article, attributes)
        expect(Mentions::CreateAll).to have_received(:call).with(article)
      end
    end

    context "when an article is being republished" do
      it "doesn't update past published_at" do
        draft.update_column(:published_at, past_time)
        attributes[:published] = true
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published).to be true
        expect(draft.published_at).to be_within(1.second).of(past_time)
      end

      it "doesn't update future published_at" do
        draft.update_column(:published_at, future_time)
        attributes[:published] = true
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published).to be true
        expect(draft.published_at).to be_within(1.second).of(future_time)
      end

      it "updates future published_at if new published_at is passed" do
        draft.update_column(:published_at, future_time)
        attributes[:published] = true
        new_published_at = 1.day.from_now
        attributes[:published_at] = new_published_at
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published).to be true
        expect(draft.published_at).to be_within(1.minute).of(new_published_at)
      end

      it "doesn't update past published_at if new published_at is passed" do
        draft.update_column(:published_at, past_time)
        attributes[:published] = true
        new_published_at = 1.day.from_now
        attributes[:published_at] = new_published_at
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published).to be true
        expect(draft.published_at).to be_within(1.second).of(past_time)
      end

      it "doesn't update published at when it is passed from frontmatter" do
        draft.update_columns(published_at: past_time)
        published_at = 10.days.from_now.strftime("%d/%m/%Y %H:%M %z")
        body_markdown = "---\ntitle: Title\npublished: false\npublished_at: #{published_at}\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        attributes = { body_markdown: body_markdown }
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.second).of(past_time)
      end

      it "doesn't update published_at when published_at is passed and an article was exported" do
        draft.update_columns(published_at: past_time, published_from_feed: true)
        new_time = 10.days.from_now
        attributes[:published_at] = new_time
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.second).of(past_time)
      end

      it "doesn't update published_at when published_at is passed (from frontmatter) and an article was exported" do
        draft.update_columns(published_at: past_time, published_from_feed: true)
        new_time = 10.days.from_now
        new_pub_at = new_time.strftime("%d/%m/%Y %H:%M %z")
        body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{new_pub_at}\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        frontmatter_attributes = { body_markdown: body_markdown }
        described_class.call(user, draft, frontmatter_attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.second).of(past_time)
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

      it "doesn't remove published_at when it's not passed" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag
        \n---\n\nHey this is the article"
        described_class.call(user, f_article, { body_markdown: body_markdown })
        f_article.reload
        expect(f_article.published_at).to be_within(1.minute).of(published_at)
      end

      it "doesn't remove published_at when it's passed" do
        body_markdown = "---\ntitle: Title\npublished: false\n
        published_at: #{published_at_str}\ndescription:\ntags: heytag\n---\n\nHey this is the article"
        described_class.call(user, f_article, { body_markdown: body_markdown })
        f_article.reload
        expect(f_article.published_at).to be_within(1.minute).of(published_at)
      end
    end

    context "when an article is being unpublished" do
      before { attributes[:published] = false }

      it "doesn't update published_at" do
        published_at = 1.day.ago
        article.update_column(:published_at, published_at)
        described_class.call(user, article, attributes)
        article.reload
        expect(article.published_at).to be_within(1.second).of(published_at)
      end

      it "doesn't send any notifications" do
        sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
          described_class.call(user, article, attributes)
        end
      end

      it "doesn't delegate to the Mentions::CreateAll service to create mentions" do
        allow(Mentions::CreateAll).to receive(:call)
        described_class.call(user, article, attributes)
        expect(Mentions::CreateAll).not_to have_received(:call).with(article)
      end

      it "destroys the preexisting notifications" do
        allow(Notification).to receive(:remove_all_by_action_without_delay).and_call_original
        described_class.call(user, article, attributes)
        attrs = { notifiable_ids: article.id, notifiable_type: "Article", action: "Published" }
        expect(Notification).to have_received(:remove_all_by_action_without_delay).with(attrs)
        # expect(ContextNotification).to have_received(:delete_all)
      end

      it "destroys the preexisting context notifications" do
        create(:context_notification, context: article, action: "Published")
        expect do
          described_class.call(user, article, attributes)
        end.to change(ContextNotification, :count).by(-1)
      end
    end

    context "when an article is updated and remains draft" do
      it "doesn't update published_at" do
        attributes[:published] = false
        described_class.call(user, draft, attributes)
        article.reload
        expect(draft.published_at).to be_nil
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
end
