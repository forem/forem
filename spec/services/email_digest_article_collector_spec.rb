require "rails_helper"

RSpec.describe EmailDigestArticleCollector, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:default_subforem) { create(:subforem, domain: "default.test") }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    if name == :article
      options[:user] ||= other_user unless options.key?(:user_id)
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super
  end

  def create_list(name, amount, *traits, **options)
    Array.new(amount) { create(name, *traits, **options) }
  end

  describe "#articles_to_send" do
    before do
      # Set up default subforem in RequestStore for testing
      RequestStore.store[:default_subforem_id] = default_subforem.id
      allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
    end

    after do
      # Clean up RequestStore after each test
      RequestStore.store[:subforem_id] = nil
      RequestStore.store[:default_subforem_id] = nil
    end

    context "when user is brand new with no-follow" do
      it "provides top 3 default-subforem articles only when at least 3 are digest-eligible", :aggregate_failures do
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        expect(described_class.new(user).articles_to_send).to be_empty

        create_list(:article, 2, public_reactions_count: 40, email_digest_eligible: false, subforem: default_subforem)
        expect(described_class.new(user).articles_to_send).to be_empty

        create(:article, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(3)
        expect(articles.first.subforem_id).to eq(default_subforem.id)
      end
    end

    context "when the user has no follows, but does have a few pageviews" do
      it "provides featured, viewed-tag, and career-tagged articles from default subforem", :aggregate_failures do
        user.page_views.create(article: create(:article, tag_list: "ruby", subforem: default_subforem))
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        create_list(:article, 2, tag_list: "ruby", public_reactions_count: 40, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(4)
        expect(articles.all? { |a| a.subforem_id == default_subforem.id }).to be true

        create_list(:article, 2, tag_list: "career", public_reactions_count: 40, score: 40, subforem: default_subforem)
        articles_with_career = described_class.new(user).articles_to_send
        expect(articles_with_career.length).to eq(6)
        expect(articles_with_career.all? { |a| a.subforem_id == default_subforem.id }).to be true
      end
    end

    context "when user follows subforems" do
      let(:followed_subforem) { create(:subforem, domain: "followed.test") }
      let(:other_subforem) { create(:subforem, domain: "other.test") }

      before do
        # Create user activity with followed subforems
        user_activity = create(:user_activity, user: user)
        user_activity.update!(alltime_subforems: [followed_subforem.id])
      end

      it "provides articles only from followed subforems" do
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: followed_subforem, featured: true,
                                 user: other_user)
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: other_subforem, featured: true,
                                 user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(3)
        expect(articles.all? { |a| a.subforem_id == followed_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == other_subforem.id }).to be false
      end

      it "falls back to default subforem if not enough articles from followed subforems" do
        create_list(:article, 1, public_reactions_count: 40, score: 40, subforem: followed_subforem,
                                 tag_list: "career", user: other_user, featured: true)
        create_list(:article, 5, public_reactions_count: 40, score: 40, subforem: default_subforem,
                                 tag_list: "productivity", user: other_user, featured: true)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(6)
        expect(articles.any? { |a| a.subforem_id == followed_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == default_subforem.id }).to be true
      end

      it "skips subforem filtering and does not load user_activity when Subforem.disabled_by_env? is true" do
        allow(Subforem).to receive(:disabled_by_env?).and_return(true)
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: other_subforem, featured: true,
                                 user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(3)
      end
    end

    context "when user follows multiple subforems" do
      let(:subforem1) { create(:subforem, domain: "subforem1.test") }
      let(:subforem2) { create(:subforem, domain: "subforem2.test") }

      before do
        # Create user activity with multiple followed subforems
        user_activity = create(:user_activity, user: user)
        user_activity.update!(alltime_subforems: [subforem1.id, subforem2.id])
      end

      it "provides articles from all followed subforems" do
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: subforem1, tag_list: "career",
                                 user: other_user)
        create_list(:article, 4, public_reactions_count: 40, score: 40, subforem: subforem2, tag_list: "productivity",
                                 user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(7)
        expect(articles.any? { |a| a.subforem_id == subforem1.id }).to be true
        expect(articles.any? { |a| a.subforem_id == subforem2.id }).to be true
      end
    end

    context "when user has custom onboarding subforem" do
      let(:custom_onboarding_subforem) { create(:subforem, domain: "custom.test") }

      before do
        user.update!(onboarding_subforem_id: custom_onboarding_subforem.id)
      end

      it "does not filter articles by subforem when user has custom onboarding subforem" do
        # Create articles in different subforems
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: custom_onboarding_subforem,
                                 tag_list: "career", user: other_user, featured: true)
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: default_subforem,
                                 tag_list: "productivity", user: other_user, featured: true)
        other_subforem = create(:subforem, domain: "other.test")
        create_list(:article, 2, public_reactions_count: 40, score: 40, subforem: other_subforem,
                                 tag_list: "ruby", user: other_user, featured: true)

        articles = described_class.new(user).articles_to_send
        # Should get articles from all subforems since we're not filtering (limited to RESULTS_COUNT = 7)
        expect(articles.length).to eq(7)
        expect(articles.any? { |a| a.subforem_id == custom_onboarding_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == default_subforem.id }).to be true
        expect(articles.any? do |a|
                 a.subforem_id != custom_onboarding_subforem.id && a.subforem_id != default_subforem.id
               end).to be true
      end

      it "still filters by subforem if user also follows subforems" do
        followed_subforem = create(:subforem, domain: "followed.test")

        # Create user activity with followed subforems
        user_activity = create(:user_activity, user: user)
        user_activity.update!(alltime_subforems: [followed_subforem.id])

        # Create articles in different subforems
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: followed_subforem,
                                 tag_list: "career", user: other_user, featured: true)
        create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: custom_onboarding_subforem,
                                 tag_list: "productivity", user: other_user, featured: true)
        create_list(:article, 2, public_reactions_count: 40, score: 40, subforem: default_subforem,
                                 tag_list: "ruby", user: other_user, featured: true)

        articles = described_class.new(user).articles_to_send
        # Should only get articles from followed subforems (following takes precedence)
        expect(articles.length).to eq(3)
        expect(articles.all? { |a| a.subforem_id == followed_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == custom_onboarding_subforem.id }).to be false
        expect(articles.any? { |a| a.subforem_id == default_subforem.id }).to be false
      end
    end

    context "when it's been less than the set number of digest email days" do
      before do
        user.follow(other_user)
        user.update(following_users_count: 1)
        create_list(:article, 3, user: other_user, public_reactions_count: 20, score: 20, subforem: default_subforem)
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: Time.current.utc)
      end

      it "returns no articles unless force_send is true", :aggregate_failures do
        Timecop.freeze(Settings::General.periodic_email_digest.days.from_now - 1) do
          expect(described_class.new(user).articles_to_send).to be_empty

          articles = described_class.new(user, force_send: true).articles_to_send
          expect(articles.length).to eq(3)
        end
      end
    end

    context "when it's been more than the set number of digest email days" do
      before do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email", user_id: user.id,
                             sent_at: Time.current.utc)
        user.follow(other_user)
        user.update(following_users_count: 1)
        create_list(:article, 3, user_id: other_user.id, public_reactions_count: 40, score: 40,
                                 subforem: default_subforem, with_tags: true)
        user.follow(Article.last.tags.first)
      end

      it "evaluates that user is ready to receive an email" do
        Timecop.freeze((Settings::General.periodic_email_digest + 1).days.from_now) do
          articles = described_class.new(user).articles_to_send
          expect(articles).not_to be_empty
        end
      end
    end

    context "when using tags" do
      it "takes 'antifollowed' tags into account", :aggregate_failures do
        articles = create_list(:article, 3, public_reactions_count: 40, score: 40,
                                            subforem: default_subforem, with_tags: true)
        tag = articles.first.tags.first
        user.follow(tag)

        digest1 = described_class.new(user).articles_to_send
        expect(digest1.size).to eq 3

        tag_follow = user.follows.first
        tag_follow.update(explicit_points: -999)

        digest2 = described_class.new(user).articles_to_send
        expect(digest2.size).to eq 0
      end
    end

    context "when articles have comment scores" do
      it "factors in comment_score to the ordering" do
        # Article 1: score 20, comment_score 0 -> total 20
        # Article 2: score 15, comment_score 10 -> total 25
        # Article 2 should come first despite lower base score
        create(:article, public_reactions_count: 20, score: 20, comment_score: 0, featured: true,
                         subforem: default_subforem, title: "A1")
        create(:article, public_reactions_count: 15, score: 15, comment_score: 10, featured: true,
                         subforem: default_subforem, title: "A2")
        create(:article, public_reactions_count: 10, score: 15, comment_score: 0, featured: true,
                         subforem: default_subforem, title: "A3")

        result = described_class.new(user).articles_to_send
        expect(result.first.title).to eq("A2")
        expect(result.second.title).to eq("A1")
      end
    end

    context "when the last email included the title of the first article" do
      it "bumps the second article to the front" do
        articles = (1..3).map do |i|
          create(:article, public_reactions_count: 40, featured: true, score: 100 - i,
                           subforem: default_subforem, user: other_user, with_tags: false)
        end

        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 25.hours.ago,
                             clicked_at: 20.hours.ago,
                             subject: articles.first.title)

        result = described_class.new(user).articles_to_send

        expect(result.first.title).to eq articles.second.title
        expect(result.last.title).to eq articles.first.title
      end
    end

    context "when the last email does not include the title of any articles" do
      it "makes first article come first" do
        articles = (1..3).map do |i|
          create(:article, public_reactions_count: 40, featured: true, score: 100 - i,
                           subforem: default_subforem, user: other_user, with_tags: false)
        end

        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 25.hours.ago,
                             clicked_at: 20.hours.ago,
                             subject: "Some other title magoo")
        result = described_class.new(user).articles_to_send

        expect(result.first.title).to eq articles.first.title
      end
    end

    context "with personalized selection via FeedConfig" do
      let(:collector) { described_class.new(user) }
      let!(:feed_config) { create(:feed_config) }

      before do
        FeatureFlag.enable(:personalized_email_digests)
        allow(described_class).to receive(:new).and_call_original
        allow(described_class).to receive(:new).with(user).and_return(collector)
        allow(collector).to receive(:field_test)
          .with(:personalized_email_digests_ab_test, participant: user)
          .and_return("personalized")
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("configured")
        allow(FeedConfig).to receive(:select_for_feed).and_wrap_original do |method, *args, **kwargs|
          selected = method.call(*args, **kwargs)
          allow(selected).to receive(:score_sql).and_return("articles.score") if selected
          selected
        end
        allow(FeedConfig).to receive(:order).and_call_original
      end

      it "returns personalized articles and sets feed_config_id when FeedConfig produces >= 3 eligible results",
         :aggregate_failures do
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = collector.articles_to_send
        expect(articles.length).to be >= 3
        expect(collector.feed_config_id).to eq(feed_config.id)
      end

      it "ignores archived feed configs during selection" do
        feed_config.update!(archived: true, feed_success_score: 999.0)
        active_config = create(:feed_config, archived: false, feed_success_score: 10.0)
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = collector.articles_to_send
        expect(articles.length).to be >= 3
        expect(collector.feed_config_id).to eq(active_config.id)
      end

      it "prioritizes digest targeting_bucket configs and excludes feed-only buckets" do
        feed_config.update!(
          targeting_bucket: FeedConfig::BUCKET_FEED_POWER_USER,
          feed_success_score: 999.0,
          feed_impressions_count: 500,
        )
        digest_config = create(
          :feed_config,
          targeting_bucket: FeedConfig::BUCKET_DIGEST,
          feed_success_score: 10.0,
          feed_impressions_count: 100,
        )
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = collector.articles_to_send
        expect(articles.length).to be >= 3
        expect(collector.feed_config_id).to eq(digest_config.id)
      end

      it "falls back to legacy selection without setting feed_config_id when < 3 articles or score_sql raises",
         :aggregate_failures do
        create_list(:article, 2, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        collector.articles_to_send
        expect(collector.feed_config_id).to be_nil

        create(:article, score: 40, featured: true, email_digest_eligible: true,
                         subforem: default_subforem, user: other_user, with_tags: false)
        expect(described_class.new(user).articles_to_send.length).to be >= 3

        allow(FeedConfig).to receive(:select_for_feed).and_return(feed_config)
        allow(feed_config).to receive(:score_sql).and_raise(StandardError, "boom")
        expect(described_class.new(user).articles_to_send.length).to be >= 3
      end

      it "skips personalized path when field test is legacy, feed_strategy is not configured, or flag is disabled",
         :aggregate_failures do
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        allow(collector).to receive(:field_test)
          .with(:personalized_email_digests_ab_test, participant: user)
          .and_return("legacy")
        described_class.new(user).articles_to_send
        expect(FeedConfig).not_to have_received(:order)

        allow(collector).to receive(:field_test)
          .with(:personalized_email_digests_ab_test, participant: user)
          .and_return("personalized")
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
        described_class.new(user).articles_to_send
        expect(FeedConfig).not_to have_received(:order)

        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("configured")
        FeatureFlag.disable(:personalized_email_digests)
        described_class.new(user).articles_to_send
        expect(FeedConfig).not_to have_received(:order)
      end

      it "uses default subforem settings in Sidekiq when RequestStore default_subforem_id is nil",
         :aggregate_failures do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_call_original
        RequestStore.store[:subforem_id] = nil
        RequestStore.store[:default_subforem_id] = nil
        Settings::UserExperience.set_feed_strategy("large_forem_experimental", subforem_id: nil)
        Settings::UserExperience.set_feed_strategy("configured", subforem_id: default_subforem.id)

        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        collector = described_class.new(user)
        articles = collector.articles_to_send

        expect(Settings::UserExperience.feed_strategy(subforem_id: nil)).to eq("large_forem_experimental")
        expect(Settings::UserExperience.feed_strategy(subforem_id: default_subforem.id)).to eq("configured")
        expect(articles.length).to eq(3)
        expect(collector.feed_config_id).to eq(feed_config.id)
      end

      it "excludes own, digest-ineligible, below-minimum-score, blocked-author, and antifollowed-tag articles",
         :aggregate_failures do
        blocked_author = create(:user)
        create(:user_block, blocker: user, blocked: blocked_author, config: "default")
        allow(UserBlock).to receive(:cached_blocked_ids_for_blocker).with(user.id).and_return([blocked_author.id])

        tag = Tag.find_by(name: "ruby") || create(:tag, name: "ruby")
        user.follow(tag)
        user.follows.find_by(followable: tag).update!(explicit_points: -999)
        allow(user).to receive(:cached_antifollowed_tag_names).and_return(["ruby"])

        offset = described_class::MINIMUM_SCORE_OFFSET
        min_score = Settings::UserExperience.home_feed_minimum_score + offset
        excluded = [
          create(:article, score: 40, featured: true, email_digest_eligible: true,
                           subforem: default_subforem, user: user),
          create(:article, score: 40, email_digest_eligible: false,
                           subforem: default_subforem, user: other_user),
          create(:article, score: min_score - 1, email_digest_eligible: true,
                           subforem: default_subforem, user: other_user),
          create(:article, score: 40, featured: true, email_digest_eligible: true,
                           subforem: default_subforem, user: blocked_author),
          create(:article, score: 40, featured: true, email_digest_eligible: true,
                           tag_list: "ruby", subforem: default_subforem, user: other_user),
        ]
        eligible = create_list(:article, 3, score: min_score + 5, featured: true, email_digest_eligible: true,
                                            tag_list: "python", subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.map(&:path)).to match_array(eligible.map(&:path))
        expect(articles.map(&:path) & excluded.map(&:path)).to be_empty
      end

      it "bumps the second article to the top when the first matches the last email subject" do
        articles = (1..3).map do |i|
          create(:article, score: 100 - i, featured: true, email_digest_eligible: true,
                           subforem: default_subforem, user: other_user, with_tags: false)
        end

        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 25.hours.ago,
                             clicked_at: 20.hours.ago,
                             subject: articles.first.title)

        result = described_class.new(user).articles_to_send
        expect(result.first.title).to eq articles.second.title
        expect(result.last.title).to eq articles.first.title
      end

      it "uses two-stage candidate pre-filtering when semantic_similarity_weight is active" do
        interest_embedding = [1.0, 0.0, 0.0] + Array.new(765, 0.0)
        aligned_embedding = [1.0, 0.0, 0.0] + Array.new(765, 0.0)
        orthogonal_embedding = [0.0, 1.0, 0.0] + Array.new(765, 0.0)

        user_activity = create(:user_activity, user: user)
        user_activity.update_column(:interest_embedding, interest_embedding)

        feed_config.update!(
          targeting_bucket: FeedConfig::BUCKET_DIGEST,
          score_weight: 1.0,
          semantic_similarity_weight: 100.0,
          semantic_candidate_limit: 350,
          randomness_weight: 0.0,
        )
        allow(FeedConfig).to receive(:select_for_feed).and_return(feed_config)
        allow(feed_config).to receive(:score_sql).and_call_original

        a1 = create(:article, score: 80, featured: true, email_digest_eligible: true,
                              subforem: default_subforem, user: other_user)
        a2 = create(:article, score: 50, featured: true, email_digest_eligible: true,
                              subforem: default_subforem, user: other_user)
        a3 = create(:article, score: 40, featured: true, email_digest_eligible: true,
                              subforem: default_subforem, user: other_user)
        a1.update_column(:semantic_embedding, orthogonal_embedding)
        a2.update_column(:semantic_embedding, aligned_embedding)
        a3.update_column(:semantic_embedding, orthogonal_embedding)

        executed_sql = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          executed_sql << payload[:sql] if payload[:sql].include?("articles.semantic_embedding <=>")
        end

        result = nil
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          result = described_class.new(user).articles_to_send
        end

        expect(executed_sql.size).to eq(1)
        expect(executed_sql.first).to include('AND "articles"."id" IN (SELECT "articles"."id" FROM "articles"')
        expect(result.first.path).to eq(a2.path)
      end

      it "applies feed_config.feed_lookback_hours when set within the digest cutoff window and caps at hard cutoff" do
        recent_articles = Array.new(3) do |i|
          create(:article, :past, score: 50 + i, featured: true, email_digest_eligible: true,
                                  subforem: default_subforem, user: other_user, past_published_at: (12 + i).hours.ago)
        end
        older_article = create(:article, :past, score: 90, featured: true, email_digest_eligible: true,
                                                subforem: default_subforem, user: other_user,
                                                past_published_at: 72.hours.ago)

        feed_config.update!(
          targeting_bucket: FeedConfig::BUCKET_DIGEST,
          score_weight: 1.0,
          feed_lookback_hours: 36,
          randomness_weight: 0.0,
        )
        allow(FeedConfig).to receive(:select_for_feed).and_return(feed_config)
        allow(feed_config).to receive(:score_sql).and_call_original

        result = described_class.new(user).articles_to_send
        result_paths = result.map(&:path)
        expect(result_paths).to match_array(recent_articles.map(&:path))
        expect(result_paths).not_to include(older_article.path)
      end

      it "caps personalized_cutoff_date at global feed_lookback_days and preserves cutoff on legacy fallback" do
        allow(Settings::UserExperience).to receive(:feed_lookback_days).and_return(1)
        # 2 articles within 24h, plus 2 articles at 36h (inside 48h config, outside 1-day global cap)
        create_list(:article, 2, :past, score: 60, featured: true, email_digest_eligible: true,
                                        subforem: default_subforem, user: other_user, past_published_at: 12.hours.ago)
        outside_global_cap = create_list(:article, 2, :past, score: 80, featured: true, email_digest_eligible: true,
                                                             subforem: default_subforem, user: other_user,
                                                             past_published_at: 36.hours.ago)

        feed_config.update!(
          targeting_bucket: FeedConfig::BUCKET_DIGEST,
          score_weight: 1.0,
          feed_lookback_hours: 48,
          randomness_weight: 0.0,
        )
        allow(FeedConfig).to receive(:select_for_feed).and_return(feed_config)
        allow(feed_config).to receive(:score_sql).and_call_original

        # Fewer than 3 articles meet the 24h capped cutoff, and legacy fallback preserves the 24h cutoff
        result = described_class.new(user).articles_to_send
        expect(result).to be_empty
        expect(result.map(&:path) & outside_global_cap.map(&:path)).to be_empty
      end
    end
  end

  describe "#should_receive_email?" do
    let(:collector) { described_class.new(user) }

    before do
      Settings::General.periodic_email_digest = 3
    end

    context "when the user clicked the last email within the lookback period" do
      it "returns true" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 2.days.ago, clicked_at: 1.day.ago)
        expect(collector.should_receive_email?).to be true
      end
    end

    context "when the user has not received any emails" do
      it "returns true" do
        expect(collector.should_receive_email?).to be true
      end
    end

    context "when the last email was received outside the periodic email digest days" do
      it "returns true" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 4.days.ago)
        expect(collector.should_receive_email?).to be true
      end
    end

    context "when the last email was received within the periodic email digest days without click" do
      it "returns false" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 2.days.ago)
        expect(collector.should_receive_email?).to be false
      end
    end

    context "when the last email was received just before the periodic email digest days limit" do
      it "returns true" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 3.days.ago)
        expect(collector.should_receive_email?).to be true
      end
    end

    context "when the last email was clicked but outside the lookback period" do
      it "returns true" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 33.days.ago, clicked_at: 32.days.ago)
        expect(collector.should_receive_email?).to be true
      end

      it "returns false when there is a sent at within the threshold" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 33.days.ago, clicked_at: 32.days.ago)
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 2.days.ago)
        expect(collector.should_receive_email?).to be false
      end
    end

    context "when the last email sent is more than 18 hours ago" do
      it "sends if last email clicked" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 19.hours.ago, clicked_at: 1.day.ago)
        expect(collector.should_receive_email?).to be true
      end

      it "does not send if last email is not clicked" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 19.hours.ago, clicked_at: nil)
        expect(collector.should_receive_email?).to be false
      end
    end

    context "when the last email sent is less than 18 hours ago" do
      it "does not send if last email is clicked" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 17.hours.ago, clicked_at: 12.hours.ago)
        expect(collector.should_receive_email?).to be false
      end

      it "does not send if last email clicked is false" do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 17.hours.ago, clicked_at: nil)
        expect(collector.should_receive_email?).to be false
      end
    end
  end
end
