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
        create_list(:article, 2, public_reactions_count: 40, score: 40, subforem: create(:subforem, domain: "other.test"), 
                                 tag_list: "ruby", user: other_user, featured: true)

        articles = described_class.new(user).articles_to_send
        # Should get articles from all subforems since we're not filtering (limited to RESULTS_COUNT = 7)
        expect(articles.length).to eq(7)
        expect(articles.any? { |a| a.subforem_id == custom_onboarding_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id == default_subforem.id }).to be true
        expect(articles.any? { |a| a.subforem_id != custom_onboarding_subforem.id && a.subforem_id != default_subforem.id }).to be true
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

    context "when the last email included the title of the first article" do
      it "bumps the second article to the front" do
        articles = create_list(:article, 5, public_reactions_count: 40, featured: true, score: 40,
                                            subforem: default_subforem)
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
        articles = create_list(:article, 5, public_reactions_count: 40, featured: true, score: 40,
                                            subforem: default_subforem)
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: 25.hours.ago,
                             clicked_at: 20.hours.ago,
                             subject: "Some other title magoo")
        result = described_class.new(user).articles_to_send

        expect(result.first.title).to eq articles.first.title
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
