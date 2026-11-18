require "rails_helper"

RSpec.describe Users::DeleteArticles, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user) }
  let(:article3) { create(:article, user: user2) }

  # Users::DeleteArticles operates directly on user/article IDs and never reads
  # user profiles, uploaded avatars, or cover images. It reads an article's
  # cached_tag_list through discussion?, which can decide whether a home-page
  # purge is queued. The create helper omits tags by default, so examples that
  # depend on tags must set tag_list, tags, or with_tags explicitly.
  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    Array.new(amount) { create(name, *traits, **options) }
  end

  it "deletes only the specified user's articles", :aggregate_failures do
    article
    article2
    article3

    described_class.call(user)

    expect(Article.find_by(id: article.id)).to be_nil
    expect(Article.find_by(id: article2.id)).to be_nil
    expect(Article.find(article3.id)).to be_present
  end

  it "deletes dependent locks, notes, activities, trend memberships, and profile pins before deleting the article",
     :aggregate_failures do
    create(:discussion_lock, article: article, locking_user: user)
    create(:context_note, article: article)
    ArticleActivity.create!(article: article)
    create(:trend_membership, article: article)
    create(:profile_pin, profile: user, pinnable: article)

    expect { described_class.call(user) }
      .to change(DiscussionLock, :count).from(1).to(0)
      .and change(ContextNote, :count).from(1).to(0)
      .and change(ArticleActivity, :count).from(1).to(0)
      .and change(TrendMembership, :count).from(1).to(0)
      .and change(ProfilePin, :count).from(1).to(0)
  end

  it "enqueues delayed cache busts for each deleted article without busting caches inline", :aggregate_failures do
    article
    article2
    allow(EdgeCache::BustArticle).to receive(:call)
    allow(EdgeCache::PurgeByKey).to receive(:call)

    sidekiq_assert_enqueued_jobs(2, only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end

    [article, article2].each do |deleted_article|
      sidekiq_assert_enqueued_with(
        job: Articles::BustDeletedArticleCacheWorker,
        args: [Articles::BustDeletedArticleCacheWorker.attributes_for(deleted_article)],
      )
    end
    expect(Articles::BustDeletedArticleCacheWorker.jobs).to all(include("at" => be > Time.current.to_f))
    expect(EdgeCache::BustArticle).not_to have_received(:call)
    expect(EdgeCache::PurgeByKey).not_to have_received(:call)
  end

  it "busts each deleted article's caches when the enqueued jobs run" do
    article
    article2
    allow(EdgeCache::BustArticle).to receive(:call)

    sidekiq_perform_enqueued_jobs(only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end

    expect(EdgeCache::BustArticle).to have_received(:call).with(an_object_having_attributes(id: article.id))
    expect(EdgeCache::BustArticle).to have_received(:call).with(an_object_having_attributes(id: article2.id))
  end

  it "keeps an article when its cache bust can't be enqueued, so a retry busts it", :aggregate_failures do
    article
    article2
    allow(Articles::BustDeletedArticleCacheWorker).to receive(:perform_in).and_raise(Redis::CannotConnectError)

    expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
    expect(Article.where(id: [article.id, article2.id]).count).to eq(2)

    allow(Articles::BustDeletedArticleCacheWorker).to receive(:perform_in).and_call_original
    sidekiq_assert_enqueued_jobs(2, only: Articles::BustDeletedArticleCacheWorker) do
      described_class.call(user)
    end
    expect(Article.where(id: [article.id, article2.id])).to be_empty
  end

  it "only keeps the article whose cache bust couldn't be enqueued", :aggregate_failures do
    article
    article2
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

  it "does nothing when the user has no articles" do
    user

    sidekiq_assert_no_enqueued_jobs do
      described_class.call(user)
    end
  end

  describe "home page cache" do
    let(:home_page_purge_args) { [["main_app_home_page"], ["/"]] }

    before { stub_const("Users::DeleteArticles::HOME_PAGE_ARTICLES_COUNT", 1) }

    it "enqueues a single home page purge when deleted articles were on the home page" do
      stub_const("Users::DeleteArticles::HOME_PAGE_ARTICLES_COUNT", 2)
      article.update_columns(hotness_score: 1_000_000)
      article2.update_columns(hotness_score: 1_000_000)

      described_class.call(user)

      home_page_purges = EdgeCache::PurgeByKeyWorker.jobs.select { |job| job["args"] == home_page_purge_args }
      expect(home_page_purges.size).to eq(1)
    end

    it "enqueues a home page purge when a deleted article was a recent discussion" do
      create(:article, user: user2, hotness_score: 10)
      article.update_columns(hotness_score: 0, cached_tag_list: "discuss", published_at: 1.hour.ago)

      sidekiq_assert_enqueued_with(job: EdgeCache::PurgeByKeyWorker, args: home_page_purge_args) do
        described_class.call(user)
      end
    end

    it "doesn't purge the home page when no deleted article was on it" do
      create(:article, user: user2, hotness_score: 10)
      article.update_columns(hotness_score: 0, cached_tag_list: "ruby")

      sidekiq_assert_not_enqueued_with(job: EdgeCache::PurgeByKeyWorker, args: home_page_purge_args) do
        described_class.call(user)
      end
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

    it "deletes comments and reactions, skips inline busts, and enqueues comment and commenter purges",
       :aggregate_failures do
      create(:reaction, reactable: comments.first, category: "like")
      sorted_comments = comments.sort_by(&:id)

      sidekiq_assert_enqueued_jobs(2, only: Users::BustCacheWorker) do
        described_class.call(user)
      end

      expect(Comment.where(commentable_id: article.id, commentable_type: "Article")).not_to exist
      expect(Reaction.where(reactable: comments.first)).to be_empty
      expect(EdgeCache::BustComment).not_to have_received(:call)
      expect(EdgeCache::BustUser).not_to have_received(:call)
      sidekiq_assert_enqueued_with(
        job: EdgeCache::PurgeByKeyWorker,
        args: [sorted_comments.map(&:record_key), sorted_comments.map(&:path)],
      )
      sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user2.id])
      sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [user3.id])
    end

    it "keeps the article's comments when their purge can't be enqueued", :aggregate_failures do
      allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_in).and_raise(Redis::CannotConnectError)

      expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
      expect(Comment.where(id: comments.map(&:id)).count).to eq(3)
      expect(Article.exists?(article.id)).to be(true)
    end

    it "busts the commenters' profiles when the enqueued jobs run", :aggregate_failures do
      sidekiq_perform_enqueued_jobs(only: Users::BustCacheWorker) { described_class.call(user) }

      expect(EdgeCache::BustUser).to have_received(:call).with(user2)
      expect(EdgeCache::BustUser).to have_received(:call).with(user3)
    end
  end
end
