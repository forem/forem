require "rails_helper"

RSpec.describe RateLimitChecker, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:rate_limit_checker) { described_class.new(user) }

  def cache_key(action)
    rate_limit_checker.__send__("limit_cache_key", action)
  end

  describe "#limit_by_action" do
    it "returns false for invalid action" do
      expect(rate_limit_checker.limit_by_action("random-nothing")).to be(false)
    end

    it "will limit action by ip_address if present" do
      action = described_class::ACTION_LIMITERS.keys.first
      limiter = described_class.new(build(:user, ip_address: "1.1.1.1"))
      expect { limiter.limit_by_action(action) }.not_to raise_error
    end

    it "raises an error if no unique component is present for a cache key" do
      action = described_class::ACTION_LIMITERS.keys.first
      limiter = described_class.new(build(:user))
      expect { limiter.limit_by_action(action) }
        .to raise_error("Invalid Cache Key: no unique component present")
    end

    # We check the excepted limits against the database, rather than our cache.
    described_class::ACTION_LIMITERS
      .except(:published_article_creation,
              :published_article_antispam_creation,
              :comment_antispam_creation).each do |action, _options|
      it "returns true if #{action} limit has been reached" do
        allow(Rails.cache).to receive(:read).with(
          cache_key(action), raw: true
        ).and_return(Settings::RateLimit.public_send(action) + 1)

        expect(rate_limit_checker.limit_by_action(action)).to be(true)
      end

      it "returns false if #{action} limit has NOT been reached" do
        allow(Rails.cache).to receive(:read).with(
          cache_key(action), raw: true
        ).and_return(Settings::RateLimit.public_send(action))

        expect(rate_limit_checker.limit_by_action(action)).to be(false)
      end
    end

    context "when creating comments" do
      before do
        allow(Settings::RateLimit).to receive(:comment_creation).and_return(1)
      end

      it "returns true if too many comments at once" do
        create_list(:comment, 2, user_id: user.id, commentable: article)
        expect(rate_limit_checker.limit_by_action("comment_creation")).to be(true)
      end

      it "returns false if allowed comment" do
        expect(rate_limit_checker.limit_by_action("comment_creation")).to be(false)
      end
    end

    it "returns true if too many published articles at once and potentially spammy" do
      allow(Settings::RateLimit).to receive(:published_article_antispam_creation).and_return(1)
      create_list(:article, 2, user_id: user.id, published: true)
      expect(rate_limit_checker.limit_by_action("published_article_antispam_creation")).to be(true)
    end

    it "returns true if too many published articles at once" do
      allow(Settings::RateLimit).to receive(:published_article_creation).and_return(1)
      create_list(:article, 2, user_id: user.id, published: true)
      expect(rate_limit_checker.limit_by_action("published_article_creation")).to be(true)
    end

    it "returns true if a user has followed more than <daily_limit> accounts today" do
      allow(rate_limit_checker)
        .to receive(:user_today_follow_count)
        .and_return(Settings::RateLimit.follow_count_daily + 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(true)
    end

    it "returns false if a user's following_users_count is less than <daily_limit>" do
      allow(user)
        .to receive(:following_users_count)
        .and_return(Settings::RateLimit.follow_count_daily - 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(false)
    end

    it "returns false if a user has followed less than <daily_limit> accounts today" do
      allow(rate_limit_checker)
        .to receive(:user_today_follow_count)
        .and_return(Settings::RateLimit.follow_count_daily)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(false)
    end

    it "returns false if published articles antispam limit has not been reached" do
      expect(described_class.new(user).limit_by_action("published_article_antispam_creation")).to be(false)
    end

    it "returns false if published articles limit has not been reached" do
      expect(described_class.new(user).limit_by_action("published_article_creation")).to be(false)
    end

    it "logs a rate limit hit to datadog" do
      allow(Rails.cache)
        .to receive(:read).with("#{user.id}_organization_creation", raw: true)
        .and_return(Settings::RateLimit.organization_creation + 1)
      allow(ForemStatsClient).to receive(:increment)
      described_class.new(user).limit_by_action("organization_creation")

      expect(ForemStatsClient).to have_received(:increment).with(
        "rate_limit.limit_reached",
        tags: ["user:#{user.id}", "action:organization_creation"],
      )
    end

    it "returns false if running in end to end tests even if the limit is reached" do
      allow(ApplicationConfig).to receive(:[]).with("E2E").and_return("true")
      allow(rate_limit_checker)
        .to receive(:user_today_follow_count)
        .and_return(Settings::RateLimit.follow_count_daily + 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(false)
    end
  end

  describe "#check_limit!" do
    it "returns nil if limit_by_action is false" do
      allow(rate_limit_checker).to receive(:limit_by_action).and_return(false)
      expect(rate_limit_checker.check_limit!(:image_upload)).to be_nil
    end

    it "raises an error if limit_by_action is true" do
      allow(rate_limit_checker).to receive(:limit_by_action).and_return(true)
      expect { rate_limit_checker.check_limit!(:image_upload) }.to raise_error(described_class::LimitReached)
    end

    it "returns nil if running in end to end tests" do
      allow(ApplicationConfig).to receive(:[]).with("E2E").and_return("true")

      expect(rate_limit_checker.check_limit!(:image_upload)).to be_nil
    end
  end

  describe "#track_limit_by_action" do
    it "increments cache for action with retry as expiration" do
      allow(Rails.cache).to receive(:increment)
      action = :image_upload
      rate_limit_checker.track_limit_by_action(action)

      key = "#{user.id}_#{action}"
      expires_in = described_class::ACTION_LIMITERS.dig(action, :retry_after)
      expect(Rails.cache).to have_received(:increment).with(key, 1, expires_in: expires_in, raw: true)
    end
  end

  describe "#limit_by_email_recipient_address" do
    before do
      allow(Settings::RateLimit).to receive(:email_recipient).and_return(1)
    end

    it "returns true if too many emails are sent to the same recipient" do
      2.times { EmailMessage.create(to: user.email, sent_at: Time.current) }
      expect(described_class.new.limit_by_email_recipient_address(user.email)).to be(true)
    end

    it "returns false if we are below the message limit for this recipient" do
      expect(described_class.new.limit_by_email_recipient_address(user.email)).to be(false)
    end
  end
end
