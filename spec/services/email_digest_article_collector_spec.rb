require "rails_helper"

RSpec.describe EmailDigestArticleCollector, type: :service do
  let(:user) { create(:user) }
  let(:default_subforem) { create(:subforem, domain: "default.test") }

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

  describe "#articles_to_send" do
    context "when user is brand new with no-follow" do
      it "provides top 3 articles from default subforem" do
        create_list(:article, 3, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(3)
        expect(articles.first.subforem_id).to eq(default_subforem.id)
      end

      it "marks as not ready if there isn't at least 3 articles" do
        create_list(:article, 2, public_reactions_count: 40, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles).to be_empty
      end

      it "marks as not ready if there isn't at least 3 email-digest-eligible articles" do
        create_list(:article, 2, public_reactions_count: 40, score: 40, subforem: default_subforem)
        create_list(:article, 2, public_reactions_count: 40, email_digest_eligible: false, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles).to be_empty
      end
    end

    context "when the user has no follows, but does have a few pageviews" do
      it "provides featured 3 articles and articles tagged with their viewed articles from default subforem" do
        user.page_views.create(article: create(:article, tag_list: "ruby", subforem: default_subforem))
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        create_list(:article, 2, tag_list: "ruby", public_reactions_count: 40, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(4)
        expect(articles.all? { |a| a.subforem_id == default_subforem.id }).to be true
      end

      it "provides articles tagged with career in addition to featured and viewed from default subforem" do
        user.page_views.create(article: create(:article, tag_list: "ruby", subforem: default_subforem))
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40, subforem: default_subforem)
        create_list(:article, 2, tag_list: "ruby", public_reactions_count: 40, score: 40, subforem: default_subforem)
        create_list(:article, 2, tag_list: "career", public_reactions_count: 40, score: 40, subforem: default_subforem)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(6)
        expect(articles.all? { |a| a.subforem_id == default_subforem.id }).to be true
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
        other_user = create(:user)
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
        other_user = create(:user)
        create_list(:article, 1, public_reactions_count: 40, score: 40, subforem: followed_subforem,
                                 tag_list: "career", user: other_user, featured: true)
        create_list(:article, 5, public_reactions_count: 40, score: 40, subforem: default_subforem,
                                 tag_list: "productivity", user: other_user, featured: true)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(6)
        expect(articles.any? { |a| a.subforem_id == followed_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == default_subforem.id }).to be true
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
        other_user = create(:user)
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
        other_user = create(:user)
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
        other_user = create(:user)
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
        author = create(:user)
        user.follow(author)
        user.update(following_users_count: 1)
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20, subforem: default_subforem)
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: Time.current.utc)
      end

      it "returns no articles when user shouldn't receive any" do
        Timecop.freeze(Settings::General.periodic_email_digest.days.from_now - 1) do
          articles = described_class.new(user).articles_to_send
          expect(articles).to be_empty
        end
      end

      it "returns articles even when last email was sent recently if force_send is true" do
        Timecop.freeze(Settings::General.periodic_email_digest.days.from_now - 1) do
          articles = described_class.new(user, force_send: true).articles_to_send
          expect(articles).not_to be_empty
          expect(articles.length).to eq(3)
        end
      end
    end

    context "when it's been more than the set number of digest email days" do
      before do
        Ahoy::Message.create(mailer: "DigestMailer#digest_email", user_id: user.id,
                             sent_at: Time.current.utc)
        author = create(:user)
        user.follow(author)
        user.update(following_users_count: 1)
        create_list(:article, 3, user_id: author.id, public_reactions_count: 40, score: 40, subforem: default_subforem)
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
        articles = create_list(:article, 3, public_reactions_count: 40, score: 40, subforem: default_subforem)
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
        articles = (1..5).map do |i|
          create(:article, public_reactions_count: 40, featured: true, score: 100 - i,
                           subforem: default_subforem)
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
        articles = (1..5).map do |i|
          create(:article, public_reactions_count: 40, featured: true, score: 100 - i,
                           subforem: default_subforem)
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
      let(:feed_config) { create(:feed_config) }

      before do
        FeatureFlag.enable(:personalized_email_digests)
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("configured")
        allow(FeedConfig).to receive(:order).and_return(instance_double(ActiveRecord::Relation, first: feed_config))
        allow(feed_config).to receive(:score_sql).and_return("articles.score")
      end

      it "returns personalized articles when FeedConfig produces >= 3 eligible results" do
        other_user = create(:user)
        create_list(:article, 4, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to be >= 3
      end

      it "falls back to legacy selection when personalized result has < 3 articles" do
        other_user = create(:user)
        # Only 2 eligible articles → personalized returns nil → legacy path runs
        create_list(:article, 2, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)
        # Add a 3rd article that the legacy path can also find
        create(:article, score: 40, featured: true, email_digest_eligible: true,
                         subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to be >= 3
      end

      it "falls back to legacy selection when personalized path raises" do
        other_user = create(:user)
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)
        allow(feed_config).to receive(:score_sql).and_raise(StandardError, "boom")

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to be >= 3
      end

      it "falls back to legacy selection when no FeedConfig exists" do
        allow(FeedConfig).to receive(:order).and_return(instance_double(ActiveRecord::Relation, first: nil))
        other_user = create(:user)
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        expect(articles.length).to be >= 3
      end

      it "skips personalized path when feed_strategy is not 'configured'" do
        allow(Settings::UserExperience).to receive(:feed_strategy).and_return("basic")
        allow(FeedConfig).to receive(:order).and_call_original

        other_user = create(:user)
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)
        described_class.new(user).articles_to_send

        expect(FeedConfig).not_to have_received(:order)
      end

      it "skips personalized path when feature flag is disabled" do
        FeatureFlag.disable(:personalized_email_digests)
        allow(FeedConfig).to receive(:order).and_call_original

        other_user = create(:user)
        create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)
        described_class.new(user).articles_to_send

        expect(FeedConfig).not_to have_received(:order)
      end

      it "never includes the user's own articles" do
        own_articles = create_list(:article, 5, score: 40, featured: true, email_digest_eligible: true,
                                                subforem: default_subforem, user: user)
        other_user = create(:user)
        create_list(:article, 3, score: 30, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        own_paths = own_articles.map(&:path)
        expect(articles.none? { |a| own_paths.include?(a.path) }).to be true
      end

      it "never includes digest-ineligible articles" do
        other_user = create(:user)
        ineligible = create_list(:article, 3, score: 40, email_digest_eligible: false,
                                              subforem: default_subforem, user: other_user)
        create_list(:article, 3, score: 30, email_digest_eligible: true, featured: true,
                                 subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        ineligible_paths = ineligible.map(&:path)
        expect(articles.none? { |a| ineligible_paths.include?(a.path) }).to be true
      end

      it "never includes articles from blocked authors" do
        blocked_author = create(:user)
        create(:user_block, blocker: user, blocked: blocked_author, config: "default")
        allow(UserBlock).to receive(:cached_blocked_ids_for_blocker).with(user.id).and_return([blocked_author.id])

        blocked_articles = create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                                    subforem: default_subforem, user: blocked_author)
        other_user = create(:user)
        create_list(:article, 3, score: 30, featured: true, email_digest_eligible: true,
                                 subforem: default_subforem, user: other_user)

        articles = described_class.new(user).articles_to_send
        blocked_paths = blocked_articles.map(&:path)
        expect(articles.none? { |a| blocked_paths.include?(a.path) }).to be true
      end

      it "bumps the second article to the top when the first matches the last email subject" do
        other_user = create(:user)
        articles = (1..5).map do |i|
          create(:article, score: 100 - i, featured: true, email_digest_eligible: true,
                           subforem: default_subforem, user: other_user)
        end

        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 25.hours.ago,
                             clicked_at: 20.hours.ago,
                             subject: articles.first.title)

        result = described_class.new(user).articles_to_send
        expect(result.first.title).to eq articles.second.title
        expect(result.last.title).to eq articles.first.title
      end

      it "never includes articles tagged with antifollowed tags" do
        other_user = create(:user)
        antifollowed_articles = create_list(:article, 3, score: 40, featured: true, email_digest_eligible: true,
                                                         tag_list: "ruby", subforem: default_subforem, user: other_user)
        create_list(:article, 3, score: 30, featured: true, email_digest_eligible: true,
                                 tag_list: "python", subforem: default_subforem, user: other_user)

        tag = Tag.find_by(name: "ruby") || create(:tag, name: "ruby")
        user.follow(tag)
        user.follows.find_by(followable: tag).update!(explicit_points: -999)
        allow(user).to receive(:cached_antifollowed_tag_names).and_return(["ruby"])

        articles = described_class.new(user).articles_to_send
        antifollowed_paths = antifollowed_articles.map(&:path)
        expect(articles.none? { |a| antifollowed_paths.include?(a.path) }).to be true
      end
    end
  end

  describe "#should_receive_email?" do
    let(:user) { create(:user) }
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
