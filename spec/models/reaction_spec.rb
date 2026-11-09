require "rails_helper"

RSpec.describe Reaction do
  let(:user) { create(:user, registered_at: 20.days.ago) }
  let(:article) { create(:article, user: user) }
  let(:reaction) { build(:reaction, reactable: article, user: user) }

  def create(name, *traits, **options)
    case name
    when :user
      return super(:user, :without_profile, *traits, profile_image: nil, **options)
    when :article
      options[:user] ||= user
      options.reverse_merge!(with_tags: false, with_main_image: false)
    when :comment
      options[:commentable] ||= article
      options[:user] ||= user
    when :reaction
      options[:reactable] ||= article
    end
    super
  end

  describe "builtin validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(ReactionCategory.all_slugs.map(&:to_s)) }

    it "validates uniqueness of user_id scoped to reactable and category" do
      expect(reaction).to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_id reactable_type category])
    end
  end

  describe ".user_has_been_given_too_many_spammy_article_reactions?" do
    it "performs a valid query for the user" do
      expect { described_class.user_has_been_given_too_many_spammy_article_reactions?(user: user) }.not_to raise_error
    end

    it "performs a valid query for the user with the include_user_profile logic" do
      expect do
        described_class.user_has_been_given_too_many_spammy_article_reactions?(user: user,
                                                                               include_user_profile: true)
      end.not_to raise_error
    end
  end

  describe "counter_culture" do
    context "when a reaction is created" do
      it "increments reaction count on user" do
        expect do
          create(:reaction, user: user)
        end.to change { user.reload.reactions_count }.by(1)
      end
    end

    context "when a reaction is destroyed" do
      it "decrements reaction count on user" do
        reaction = create(:reaction, user: user)
        expect do
          reaction.destroy
        end.to change { user.reload.reactions_count }.by(-1)
      end
    end
  end

  describe "validations" do
    it "validates allowed categories, untrusted negative reactions, and published articles", :aggregate_failures do
      allow(Settings::General).to receive(:mascot_user_id).and_return(user.id + 1)

      reaction.category = "like"
      expect(reaction).to be_valid

      %w[woozlewazzle vomit thumbsdown].each do |invalid_category|
        reaction.category = invalid_category
        expect(reaction).not_to be_valid
      end

      article.update_column(:published, false)
      expect(build(:reaction, user: user, reactable: article)).not_to be_valid
    end

    context "when user is trusted" do
      before { reaction.user.add_role(:trusted) }

      it "allows vomit and thumbsdown reactions for users with trusted role", :aggregate_failures do
        %w[vomit thumbsdown].each do |category|
          reaction.category = category
          expect(reaction).to be_valid
        end
      end
    end
  end

  describe "#skip_notification_for?" do
    let(:receiver) { build(:user) }
    let(:reaction) { build(:reaction, reactable: build(:article), user: nil) }

    it "is normally false" do
      expect(reaction.skip_notification_for?(receiver)).to be(false)
    end

    it "is true when points are negative" do
      reaction.points = -2
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end

    it "is true when the person who reacted is the same as the reactable owner" do
      user_id = User.maximum(:id).to_i + 1
      reaction.user_id = user_id
      reaction.reactable.user_id = user_id
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end

    it "is true for inavlidated reactions" do
      reaction.status = "invalid"
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end

    it "is true when the reaction is a bookmark" do
      reaction.category = "readinglist"
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end

    context "when reactable is a user" do
      let(:user) { build_stubbed(:user) }
      let(:reaction) { build(:reaction, reactable: user, user: nil) }

      it "returns true if the reactable is the user that reacted" do
        reaction.user_id = user.id
        expect(reaction.skip_notification_for?(receiver)).to be(true)
      end

      it "returns false if the reactable is not the user that reacted" do
        reaction.user_id = build_stubbed(:user).id
        expect(reaction.skip_notification_for?(receiver)).to be(false)
      end
    end
  end

  describe ".count_for_article" do
    it "counts the reactions an article has grouped by category" do
      create(:reaction, reactable: article, user: user, category: "like")
      create(:reaction, reactable: article, user: user, category: "unicorn")

      expected_result = [
        { category: "like", count: 1 },
        { category: "unicorn", count: 1 },
        { category: "exploding_head", count: 0 },
        { category: "fire", count: 0 },
        { category: "raised_hands", count: 0 },
        { category: "readinglist", count: 0 },
      ]
      expect(described_class.count_for_article(article.id)).to match_array(expected_result)
    end

    it "does not pollute the .public_category scope on subsequent calls" do
      # Regression: count_for_article and .for_analytics used to mutate the
      # memoized @public_reaction_types array with `<< 'readinglist'`,
      # permanently corrupting .public_category for the rest of the process.
      described_class.count_for_article(article.id)
      described_class.for_analytics

      expect(described_class.public_category.where_values_hash["category"])
        .not_to include("readinglist")
    end
  end

  context "when callbacks are called after create" do
    describe "field tests" do
      let!(:user) { create(:user, :trusted) }

      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Users::RecordFieldTestEventWorker)
      end

      it "enqueues a Users::RecordFieldTestEventWorker for giving a like to an article" do
        article = create(:article, user: user)
        sidekiq_assert_enqueued_jobs(1, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: article, user: user, category: "like")
        end
      end

      it "does not enqueue a Users::RecordFieldTestEventWorker for giving a privileged reaction to an article" do
        article = create(:article, user: user)
        sidekiq_assert_enqueued_jobs(0, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: article, user: user, category: "thumbsdown")
        end
      end

      it "does not enqueue a Users::RecordFieldTestEventWorker for giving a like to a comment" do
        comment = create(:comment, user: user)
        sidekiq_assert_enqueued_jobs(0, only: Users::RecordFieldTestEventWorker) do
          create(:reaction, reactable: comment, user: user, category: "like")
        end
      end
    end

    describe "slack messages" do
      let!(:user) { create(:user, :trusted) }
      let!(:article) { create(:article, user: user) }

      before do
        # making sure there are no other enqueued jobs from other tests
        sidekiq_perform_enqueued_jobs(only: Slack::Messengers::Worker)
      end

      it "queues a slack message to be sent for a vomit reaction" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "vomit")
        end
      end

      it "does not queue a message for a like reaction" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "like")
        end
      end

      it "does not queue a message for a thumbsdown reaction" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          create(:reaction, reactable: article, user: user, category: "thumbsdown")
        end
      end
    end
  end

  context "when callbacks are called after save" do
    let!(:reaction) { build(:reaction, category: "like", reactable: article, user: user) }

    describe "enqueues the correct worker" do
      it "BustReactableCacheWorker" do
        sidekiq_assert_enqueued_with(job: Reactions::BustReactableCacheWorker) do
          reaction.save
        end
      end

      it "BustHomepageCacheWorker" do
        sidekiq_assert_enqueued_with(job: Reactions::BustHomepageCacheWorker) do
          reaction.save
        end
      end
    end

    it "updates updated_at if the reactable is a comment" do
      updated_at = 1.day.ago
      comment = create(:comment, commentable: article, updated_at: updated_at)
      sidekiq_perform_enqueued_jobs do
        reaction.update(reactable: comment)
      end
      expect(comment.reload.updated_at).to be > updated_at
    end
  end

  context "when callbacks are called before destroy" do
    let!(:reaction) { create(:reaction, reactable: article, user: user) }

    it "enqueues ScoreCalcWorker, updates reactable, and busts reactable and article caches", :aggregate_failures do
      allow(Reactions::UpdateRelevantScoresWorker).to receive(:perform_async)
      allow(reaction).to receive(:bust_reactable_cache_without_delay).and_call_original
      allow(EdgeCache::BustArticle).to receive(:call)

      sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
        reaction.destroy
      end

      expect(Reactions::UpdateRelevantScoresWorker).to have_received(:perform_async)
      expect(reaction).to have_received(:bust_reactable_cache_without_delay)
      expect(EdgeCache::BustArticle).to have_received(:call)
    end

    it "does not bust article if it is not the last public reaction" do
      create(:reaction, reactable: article, user: create(:user))
      allow(EdgeCache::BustArticle).to receive(:call)
      reaction.destroy
      expect(EdgeCache::BustArticle).not_to have_received(:call)
    end
  end

  describe ".related_negative_reactions_for_user" do
    let(:moderator) { create(:user, :trusted) }

    it "returns vomit reactions on user's articles" do
      article = create(:article, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: article)

      expect(described_class.related_negative_reactions_for_user(user).first.id).to eq(reaction.id)
    end

    it "returns vomit reactions on user's comments" do
      comment = create(:comment, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: comment)

      expect(described_class.related_negative_reactions_for_user(user).first.id).to eq(reaction.id)
    end

    it "returns the user's vomit reactions" do
      reaction = create(:vomit_reaction, user: moderator, reactable: user)

      expect(described_class.related_negative_reactions_for_user(moderator).first.id).to eq(reaction.id)
    end
  end

  describe ".contradictory_mod_reactions" do
    let(:moderator) { create(:user, :trusted) }

    it "returns the contradictary reactions related to the category passed in" do
      article = create(:article, user: moderator)
      reaction = create(:vomit_reaction, user: moderator, reactable: article)

      expect(described_class.contradictory_mod_reactions(
        category: "thumbsup",
        reactable_id: article.id,
        reactable_type: "Article",
        user: moderator,
      ).first).to eq(reaction)
    end
  end

  describe ".readinglist_for_user finds reactions from given user" do
    before do
      user.reactions.create(reactable: article, category: "readinglist")
      comment = create(:comment)
      user.reactions.create(reactable: comment, category: "readinglist")
      article2 = create(:article)
      user.reactions.create(reactable: article2, category: "like")

      user2 = create(:user)
      user2.reactions.create(reactable: article, category: "readinglist")
    end

    it "returns un-archived reactions on articles" do
      expect(described_class.readinglist_for_user(user).pluck(:reactable_id)).to contain_exactly(article.id)
    end
  end

  describe ".live_reactable" do
    let(:moderator) { create(:user, :trusted) }

    it "returns reactions on articles where article is published" do
      article = create(:article, published: true)
      reaction = create(:vomit_reaction, user: moderator, reactable: article)

      expect(described_class.live_reactable.to_a).to eq([reaction])
    end

    it "does not return reaction on articles where not published" do
      article = create(:article)
      create(:vomit_reaction, user: moderator, reactable: article)
      article.update_column(:published, false)

      expect(described_class.live_reactable.to_a).to eq([])
    end

    it "returns reactions on comments" do
      comment = create(:comment)
      reaction = create(:vomit_reaction, user: moderator, reactable: comment)

      expect(described_class.live_reactable).to eq([reaction])
    end

    it "returns reactions to users" do
      user = create(:user)
      reaction = create(:vomit_reaction, user: moderator, reactable: user)

      expect(described_class.live_reactable.to_a).to eq([reaction])
    end

    it "does not return reactions to users who are deemed spam already" do
      user = create(:user, username: "spam_400")
      create(:vomit_reaction, user: moderator, reactable: user)

      expect(described_class.live_reactable.to_a).to eq([])
    end
  end

  describe "cache invalidation" do
    it "calls bust_reaction_counts_cache and invalidates reaction_counts_for_reactable cache on create, update, and destroy", # rubocop:disable Layout/LineLength
       :aggregate_failures do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"
      like_reaction = create(:reaction, reactable: article, category: "like", user: user)

      article.public_reaction_categories
      expect(Rails.cache.exist?(cache_key)).to be(true)

      fire_reaction = build(:reaction, reactable: article, category: "fire", user: user)
      allow(fire_reaction).to receive(:bust_reaction_counts_cache).and_call_original
      expect do
        fire_reaction.save!
      end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      expect(fire_reaction).to have_received(:bust_reaction_counts_cache)

      article.public_reaction_categories
      expect do
        like_reaction.update!(category: "unicorn")
      end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)

      article.public_reaction_categories
      expect do
        like_reaction.destroy
      end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
    end
  end

  describe "#enqueue_article_activity_update callback" do
    it "enqueues with action=create and the reaction payload on create" do
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      create(:reaction, reactable: article, user: user, category: "like")
      expect(Articles::UpdateArticleActivityWorker)
        .to have_received(:perform_async)
        .with(article.id, "reaction", "create",
              hash_including("category" => "like", "user_id" => user.id))
    end

    it "enqueues with action=destroy on destroy" do
      reaction = create(:reaction, reactable: article, user: user, category: "like")
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      reaction.destroy
      expect(Articles::UpdateArticleActivityWorker)
        .to have_received(:perform_async)
        .with(article.id, "reaction", "destroy", hash_including("category" => "like"))
    end

    it "does not enqueue when reactable is not an Article" do
      comment = create(:comment, commentable: article, user: user)
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)
      create(:reaction, reactable: comment, user: user, category: "like")
      expect(Articles::UpdateArticleActivityWorker).not_to have_received(:perform_async)
    end
  end

  describe "update user interest embedding" do
    it "enqueues the worker when a public reaction is created on an article" do
      allow(UpdateUserInterestEmbeddingWorker).to receive(:perform_async)
      create(:reaction, reactable: article, user: user, category: "like")
      expect(UpdateUserInterestEmbeddingWorker).to have_received(:perform_async).with(user.id, article.id, 0.2)
    end

    it "does not enqueue the worker for non-public reactions" do
      allow(UpdateUserInterestEmbeddingWorker).to receive(:perform_async)
      create(:reaction, reactable: article, user: user, category: "readinglist")
      expect(UpdateUserInterestEmbeddingWorker).not_to have_received(:perform_async)
    end

    it "does not enqueue the worker for non-article reactables" do
      comment = create(:comment, commentable: article, user: user)
      allow(UpdateUserInterestEmbeddingWorker).to receive(:perform_async)
      create(:reaction, reactable: comment, user: user, category: "like")
      expect(UpdateUserInterestEmbeddingWorker).not_to have_received(:perform_async)
    end
  end

  describe "update user reading list activity" do
    it "enqueues the worker when a readinglist reaction is created on an article" do
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      create(:reaction, reactable: article, user: user, category: "readinglist")
      expect(Users::UpdateUserReadingListActivityWorker).to have_received(:perform_async).with(user.id)
    end

    it "enqueues the worker when a readinglist reaction is destroyed" do
      reading_reaction = create(:reaction, reactable: article, user: user, category: "readinglist")
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      reading_reaction.destroy
      expect(Users::UpdateUserReadingListActivityWorker).to have_received(:perform_async).with(user.id)
    end

    it "enqueues the worker when a readinglist reaction is archived" do
      reading_reaction = create(:reaction, reactable: article, user: user, category: "readinglist")
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      reading_reaction.update!(status: "archived")
      expect(Users::UpdateUserReadingListActivityWorker).to have_received(:perform_async).with(user.id)
    end

    it "enqueues the worker when a readinglist reaction changes category away from readinglist" do
      reading_reaction = create(:reaction, reactable: article, user: user, category: "readinglist")
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      reading_reaction.update!(category: "like")
      expect(Users::UpdateUserReadingListActivityWorker).to have_received(:perform_async).with(user.id)
    end

    it "does not enqueue the worker for non-readinglist reactions" do
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      create(:reaction, reactable: article, user: user, category: "like")
      expect(Users::UpdateUserReadingListActivityWorker).not_to have_received(:perform_async)
    end

    it "does not enqueue the worker when a non-readinglist reaction is destroyed" do
      like_reaction = create(:reaction, reactable: article, user: user, category: "like")
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      like_reaction.destroy
      expect(Users::UpdateUserReadingListActivityWorker).not_to have_received(:perform_async)
    end

    it "does not enqueue the worker for non-article reactables" do
      comment = create(:comment, commentable: article, user: user)
      allow(Users::UpdateUserReadingListActivityWorker).to receive(:perform_async)
      create(:reaction, reactable: comment, user: user, category: "readinglist")
      expect(Users::UpdateUserReadingListActivityWorker).not_to have_received(:perform_async)
    end
  end

  describe "when destroyed via reactable association" do
    let(:reactor) { create(:user) }

    before do
      create(:reaction, reactable: article, user: reactor, category: "like")
    end

    it "skips reactable cache busting and article activity workers" do
      allow(Reactions::BustReactableCacheWorker).to receive(:new)
      allow(Reactions::BustHomepageCacheWorker).to receive(:perform_async)
      allow(Articles::UpdateArticleActivityWorker).to receive(:perform_async)

      article.destroy!

      expect(Reactions::BustReactableCacheWorker).not_to have_received(:new)
      expect(Reactions::BustHomepageCacheWorker).not_to have_received(:perform_async)
      expect(Articles::UpdateArticleActivityWorker).not_to have_received(:perform_async)
    end

    it "decrements the reactor user reactions_count without failing on drifted article public_reactions_count" do
      article.update_columns(public_reactions_count: 0)

      expect { article.destroy! }.to change { reactor.reload.reactions_count }.by(-1)
    end
  end
end
