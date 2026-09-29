require "rails_helper"

RSpec.describe Users::DeleteComments, type: :service do
  let(:user) { create(:user) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, user: user, commentable: article) }

  before do
    create_list(:comment, 2, commentable: article, user: user)

    allow(EdgeCache::BustComment).to receive(:call)
    allow(EdgeCache::BustUser).to receive(:call)
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "destroys user comments" do
    comment
    described_class.call(user)
    expect(Comment.where(user_id: user.id).any?).to be false
  end

  it "deletes the comments' reactions" do
    create(:reaction, reactable: comment, category: "like")

    expect do
      described_class.call(user)
    end.to change(Reaction, :count).by(-1)
  end

  it "doesn't bust caches inline" do
    described_class.call(user)

    expect(EdgeCache::BustComment).not_to have_received(:call)
    expect(EdgeCache::BustUser).not_to have_received(:call)
    expect(EdgeCache::PurgeByKey).not_to have_received(:call)
  end

  it "enqueues a purge of the deleted comments" do
    comments = user.comments.order(:id).to_a

    sidekiq_assert_enqueued_with(
      job: EdgeCache::PurgeByKeyWorker,
      args: [comments.map(&:record_key), comments.map(&:path)],
    ) do
      described_class.call(user)
    end
  end

  it "batches the comment purges" do
    allow(user.comments).to receive(:includes).and_wrap_original do |original, *args|
      relation = original.call(*args)
      allow(relation).to receive(:find_in_batches).and_wrap_original do |find_in_batches, **_kwargs, &block|
        find_in_batches.call(batch_size: 1, &block)
      end
      relation
    end

    # 2 batches of one comment + the user's profile
    sidekiq_assert_enqueued_jobs(3, only: EdgeCache::PurgeByKeyWorker) do
      described_class.call(user)
    end
  end

  it "enqueues one commentable cache bust per commented-on record" do
    other_article = create(:article)
    create(:comment, user: user, commentable: other_article)

    sidekiq_assert_enqueued_jobs(2, only: Comments::BustCommentableCacheWorker) do
      described_class.call(user)
    end
    sidekiq_assert_enqueued_with(job: Comments::BustCommentableCacheWorker, args: ["Article", article.id])
    sidekiq_assert_enqueued_with(job: Comments::BustCommentableCacheWorker, args: ["Article", other_article.id])
  end

  it "enqueues a purge of the user's profile" do
    sidekiq_assert_enqueued_with(
      job: EdgeCache::PurgeByKeyWorker,
      args: [user.profile_cache_keys, user.profile_cache_bust_paths],
    ) do
      described_class.call(user)
    end
  end

  it "busts the caches when the enqueued jobs run" do
    comments = user.comments.order(:id).to_a

    sidekiq_perform_enqueued_jobs { described_class.call(user) }

    expect(EdgeCache::PurgeByKey).to have_received(:call)
      .with(comments.map(&:record_key), fallback_paths: comments.map(&:path))
    expect(EdgeCache::PurgeByKey).to have_received(:call)
      .with(user.profile_cache_keys, fallback_paths: user.profile_cache_bust_paths)
    expect(EdgeCache::BustComment).to have_received(:call).with(article)
  end

  it "does nothing when the user has no comments" do
    user.comments.delete_all

    sidekiq_assert_no_enqueued_jobs do
      described_class.call(user)
    end
  end

  it "destroys moderation notifications properly" do
    create(:notification, notifiable: comment, action: "Moderation", user: trusted_user)
    described_class.call(user)
    expect(Notification.count).to eq 0
  end

  it "only destroys notifications about the deleted comments" do
    other_comment = create(:comment, commentable: article)
    create(:notification, notifiable: comment, user: trusted_user)
    kept_notification = create(:notification, notifiable: other_comment, user: trusted_user)

    described_class.call(user)

    expect(Notification.ids).to eq([kept_notification.id])
  end
end
