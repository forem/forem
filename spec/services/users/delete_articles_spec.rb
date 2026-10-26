require "rails_helper"

RSpec.describe Users::DeleteArticles, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:article2) { create(:article, user: user) }
  let!(:article3) { create(:article, user: user2) }

  it "deletes articles" do
    described_class.call(user)
    expect(Article.find_by(id: article.id)).to be_nil
    expect(Article.find_by(id: article2.id)).to be_nil
    expect(Article.find(article3.id)).to be_present
  end

  it "deletes the articles' discussion locks before deleting the article" do
    create(:discussion_lock, article: article, locking_user: user)
    expect do
      described_class.call(user)
    end.to change(DiscussionLock, :count).from(1).to(0)
  end

  it "deletes the articles' context notes before deleting the article" do
    create(:context_note, article: article)
    expect do
      described_class.call(user)
    end.to change(ContextNote, :count).from(1).to(0)
  end

  it "deletes the articles' article activities before deleting the article" do
    ArticleActivity.create!(article: article)
    expect do
      described_class.call(user)
    end.to change(ArticleActivity, :count).from(1).to(0)
  end

  it "deletes the articles' trend memberships before deleting the article" do
    create(:trend_membership, article: article)
    expect do
      described_class.call(user)
    end.to change(TrendMembership, :count).from(1).to(0)
  end

  context "when pinned articles exist" do
    before { create(:profile_pin, profile: user, pinnable: article) }

    it "deletes pinned article references with the article" do
      expect do
        described_class.call(user)
      end.to change(ProfilePin, :count).from(1).to(0)
    end
  end

  it "doesn't bust caches inline" do
    allow(EdgeCache::BustArticle).to receive(:call)
    allow(EdgeCache::PurgeByKey).to receive(:call)

    described_class.call(user)

    expect(EdgeCache::BustArticle).not_to have_received(:call)
    expect(EdgeCache::PurgeByKey).not_to have_received(:call)
  end

  it "enqueues a cache bust for each deleted article" do
    sidekiq_assert_enqueued_jobs(2, only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end
    [article, article2].each do |deleted_article|
      sidekiq_assert_enqueued_with(
        job: Articles::BustDeletedArticleCacheWorker,
        args: [Articles::BustDeletedArticleCacheWorker.attributes_for(deleted_article)],
      )
    end
  end

  it "busts each deleted article's caches when the enqueued jobs run" do
    allow(EdgeCache::BustArticle).to receive(:call)

    sidekiq_perform_enqueued_jobs(only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end

    expect(EdgeCache::BustArticle).to have_received(:call).with(an_object_having_attributes(id: article.id))
    expect(EdgeCache::BustArticle).to have_received(:call).with(an_object_having_attributes(id: article2.id))
  end

  it "keeps an article when its cache bust can't be enqueued, so a retry busts it", :aggregate_failures do
    allow(Articles::BustDeletedArticleCacheWorker).to receive(:perform_in).and_raise(Redis::CannotConnectError)

    expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
    expect(Article.where(id: [article.id, article2.id]).count).to eq(2)

    allow(Articles::BustDeletedArticleCacheWorker).to receive(:perform_in).and_call_original
    sidekiq_assert_enqueued_jobs(2, only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end
    expect(Article.where(id: [article.id, article2.id])).to be_empty
  end

  it "only keeps the article whose cache bust couldn't be enqueued" do
    calls = 0
    allow(Articles::BustDeletedArticleCacheWorker).to receive(:perform_in).and_wrap_original do |original, *args|
      calls += 1
      raise Redis::CannotConnectError if calls == 2

      original.call(*args)
    end

    expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
    expect(Article.where(id: [article.id, article2.id]).count).to eq(1)
    expect(Articles::BustDeletedArticleCacheWorker.jobs.size).to eq(1)
  end

  it "delays the article cache busts until the deletion is committed" do
    described_class.call(user)

    expect(Articles::BustDeletedArticleCacheWorker.jobs).to all(include("at" => be > Time.current.to_f))
  end

  it "does nothing when the user has no articles" do
    sidekiq_assert_no_enqueued_jobs do
      described_class.call(user2.tap { |u| u.articles.delete_all })
    end
  end

  describe "home page cache" do
    let(:home_page_purge_args) { [["main_app_home_page"], ["/"]] }

    before { Article.where.not(user_id: user.id).update_all(hotness_score: 0) }

    it "enqueues a home page purge when a deleted article was on the home page" do
      article.update_columns(hotness_score: 1_000_000)

      sidekiq_assert_enqueued_with(job: EdgeCache::PurgeByKeyWorker, args: home_page_purge_args) do
        described_class.call(user)
      end
    end

    it "enqueues a home page purge when a deleted article was a recent discussion" do
      Article.update_all(hotness_score: 0)
      create_list(:article, 4, user: user2, hotness_score: 10)
      article.update_columns(cached_tag_list: "discuss", published_at: 1.hour.ago)

      sidekiq_assert_enqueued_with(job: EdgeCache::PurgeByKeyWorker, args: home_page_purge_args) do
        described_class.call(user)
      end
    end

    it "doesn't purge the home page when no deleted article was on it" do
      Article.update_all(hotness_score: 0)
      # the factory tags articles with #discuss
      Article.where(user_id: user.id).update_all(cached_tag_list: "ruby")
      create_list(:article, 4, user: user2, hotness_score: 10)

      sidekiq_assert_not_enqueued_with(job: EdgeCache::PurgeByKeyWorker, args: home_page_purge_args) do
        described_class.call(user)
      end
    end

    it "only enqueues one home page purge" do
      Article.where(user_id: user.id).update_all(hotness_score: 1_000_000)

      described_class.call(user)

      home_page_purges = EdgeCache::PurgeByKeyWorker.jobs.select { |job| job["args"] == home_page_purge_args }
      expect(home_page_purges.size).to eq(1)
    end
  end

  context "with comments" do
    let(:user3) { create(:user) }
    let!(:comments) do
      create_list(:comment, 2, commentable: article, user: user2) +
        [create(:comment, commentable: article, user: user3)]
    end

    before do
      allow(EdgeCache::BustComment).to receive(:call)
      allow(EdgeCache::BustArticle).to receive(:call)
      allow(EdgeCache::BustUser).to receive(:call)
      allow(EdgeCache::PurgeByKey).to receive(:call)
    end

    it "deletes articles' comments" do
      described_class.call(user)
      expect(Comment.where(commentable_id: article.id, commentable_type: "Article").any?).to be false
    end

    it "deletes the comments' reactions" do
      create(:reaction, reactable: comments.first, category: "like")

      described_class.call(user)

      expect(Reaction.where(reactable: comments.first)).to be_empty
    end

    it "doesn't bust comment or commenter caches inline" do
      described_class.call(user)

      expect(EdgeCache::BustComment).not_to have_received(:call)
      expect(EdgeCache::BustUser).not_to have_received(:call)
    end

    it "enqueues a purge of the deleted comments" do
      sorted_comments = comments.sort_by(&:id)

      sidekiq_assert_enqueued_with(
        job: EdgeCache::PurgeByKeyWorker,
        args: [sorted_comments.map(&:record_key), sorted_comments.map(&:path)],
      ) do
        described_class.call(user)
      end
    end

    it "keeps the article's comments when their purge can't be enqueued", :aggregate_failures do
      allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_in).and_raise(Redis::CannotConnectError)

      expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
      expect(Comment.where(id: comments.map(&:id)).count).to eq(3)
      expect(Article.exists?(article.id)).to be(true)
    end

    it "enqueues one profile cache bust per distinct commenter" do
      sidekiq_assert_enqueued_jobs(2, only: Users::BustCacheWorker) do
        described_class.call(user)
      end
      sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user2.id])
      sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user3.id])
    end

    it "busts the commenters' profiles when the enqueued jobs run" do
      sidekiq_perform_enqueued_jobs { described_class.call(user) }

      expect(EdgeCache::BustUser).to have_received(:call).with(user2)
      expect(EdgeCache::BustUser).to have_received(:call).with(user3)
    end
  end
end
