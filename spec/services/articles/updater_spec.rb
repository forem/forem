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
    context "when an article is updated and published the first time" do
      before { attributes[:published] = true }

      # it "enqueues a job to send a notification" do
      #   sidekiq_assert_enqueued_with(job: Notifications::NotifiableActionWorker) do
      #     described_class.call(user, draft, attributes)
      #   end
      # end

      # it "delegates to the Mentions::CreateAll service to create mentions" do
      #   allow(Mentions::CreateAll).to receive(:call)
      #   described_class.call(user, draft, attributes)
      #   expect(Mentions::CreateAll).to have_received(:call).with(draft)
      # end

      # in case the article was published and unpublished before
      it "updates published_at to the current time when no published_at passed" do
        attributes[:published_at] = nil
        past_time = 1.year.ago
        draft.update_column(:published_at, past_time)
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.minute).of(Time.current)
      end

      it "updates published_at to the current time when a past published_at is passed" do
        attributes[:published_at] = "2020-04-05 20:20"
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.minute).of(Time.current)
      end

      it "doesn't update published_at when a future published_at is passed" do
        attributes[:published_at] = 1.day.from_now
        described_class.call(user, draft, attributes)
        draft.reload
        expect(draft.published_at).to be_within(1.second).of(attributes[:published_at])
      end

      it "doesn't update published_at when a past published_at is passed and an article was exported" do
        past = 10.days.ago
        draft.update_columns(published_at: past, published_from_feed: true)
        attributes[:published_at] = past
        described_class.call(user, draft, attributes)
        expect(draft.published_at).to be_within(1.second).of(past)
      end
    end

    context "when an article is being updated and has already been published" do
      # it "doesn't enqueue a job to send a notification" do
      #   attributes[:published] = true
      #   sidekiq_assert_not_enqueued_with(job: Notifications::NotifiableActionWorker) do
      #     described_class.call(user, article, attributes)
      #   end
      # end

      it "doesn't update published_at" do
        attributes[:published] = true
        past_time = 1.year.ago
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

    context "when an article is unpublished" do
      before { attributes[:published] = false }

      it "nullifies published_at" do
        published_at = 1.day.ago
        article.update_column(:published_at, published_at)
        described_class.call(user, article, attributes)
        article.reload
        expect(article.published_at).to be_nil
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

      it "destroys the pre-existing notifications" do
        allow(Notification).to receive(:remove_all_by_action_without_delay).and_call_original
        described_class.call(user, article, attributes)
        attrs = { notifiable_ids: article.id, notifiable_type: "Article", action: "Published" }
        expect(Notification).to have_received(:remove_all_by_action_without_delay).with(attrs)
        # expect(ContextNotification).to have_received(:delete_all)
      end

      it "destroys the pre-existing context notifications" do
        create(:context_notification, context: article, action: "Published")
        expect do
          described_class.call(user, article, attributes)
        end.to change(ContextNotification, :count).by(-1)
      end
    end

    context "when an article is updated and remains unpublished" do
      it "doesn't update published_at" do
        attributes[:published] = false
        described_class.call(user, draft, attributes)
        article.reload
        expect(draft.published_at).to be_nil
      end
    end

    context "when an article is unpublished and contains comments" do
      let!(:comment) { create(:comment, user_id: user.id, commentable: article) }
      let(:notification) do
        create(:notification, user: user, notifiable_id: comment.id, notifiable_type: "Comment")
      end

      before do
        attributes[:published] = false
        allow(Notification).to receive(:remove_all).and_call_original
      end

      it "removes any pre-existing comment notifications but does not delete the comment" do
        described_class.call(user, article, attributes)

        expect(Notification).to have_received(:remove_all).with(
          notifiable_ids: [comment.id], notifiable_type: "Comment",
        )
        expect(article.comments.length).to eq(1)
      end
    end

    context "when an article is unpublished and contains mentions" do
      let!(:mention) { create(:mention, mentionable: article, user: user) }
      let(:notification) do
        create(:notification, user: user, notifiable_id: mention.id, notifiable_type: "Mention")
      end

      before do
        attributes[:published] = false
        allow(Notification).to receive(:remove_all).and_call_original
      end

      it "removes any pre-existing mention notifications but does not delete the mention" do
        described_class.call(user, article, attributes)

        expect(Notification).to have_received(:remove_all).with(
          notifiable_ids: [mention.id], notifiable_type: "Mention",
        )
        expect(article.mentions.length).to eq(1)
      end
    end
  end
end
