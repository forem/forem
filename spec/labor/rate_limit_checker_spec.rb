require "rails_helper"

RSpec.describe RateLimitChecker, type: :labor do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe "#limit_by_action" do
    let(:rate_limit_checker) { described_class.new(user) }

    it "returns false for invalid action" do
      expect(rate_limit_checker.limit_by_action("random-nothing")).to be(false)
    end

    context "when creating comments" do
      before do
        allow(SiteConfig).to receive(:rate_limit_comment_creation).and_return(1)
      end

      it "returns true if too many comments at once" do
        create_list(:comment, 2, user_id: user.id, commentable: article)
        expect(rate_limit_checker.limit_by_action("comment_creation")).to be(true)
      end

      it "sends a slack message if a user leaves too any messages" do
        create_list(:comment, 2, user_id: user.id, commentable: article)

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          rate_limit_checker.limit_by_action("comment_creation")
        end
      end

      it "returns false if allowed comment" do
        expect(rate_limit_checker.limit_by_action("comment_creation")).to be(false)
      end
    end

    it "returns true if too many published articles at once" do
      allow(SiteConfig).to receive(:rate_limit_published_article_creation).and_return(1)
      create_list(:article, 2, user_id: user.id, published: true)
      expect(rate_limit_checker.limit_by_action("published_article_creation")).to be(true)
    end

    it "returns true if a user has followed more than <daily_limit> accounts today" do
      allow(rate_limit_checker).
        to receive(:user_today_follow_count).
        and_return(SiteConfig.rate_limit_follow_count_daily + 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(true)
    end

    it "returns false if a user's following_users_count is less than <daily_limit>" do
      allow(user).
        to receive(:following_users_count).
        and_return(SiteConfig.rate_limit_follow_count_daily - 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(false)
    end

    it "returns false if a user has followed less than <daily_limit> accounts today" do
      allow(rate_limit_checker).
        to receive(:user_today_follow_count).
        and_return(SiteConfig.rate_limit_image_upload + 1)

      expect(rate_limit_checker.limit_by_action("follow_account")).to be(false)
    end

    it "returns false if published articles limit has not been reached" do
      expect(described_class.new(user).limit_by_action("published_article_creation")).to be(false)
    end

    it "returns false if a user uploads too many images" do
      allow(rate_limit_checker).
        to receive(:track_image_uploads).
        and_return(SiteConfig.rate_limit_follow_count_daily - 1)

      expect(rate_limit_checker.limit_by_action("image_upload")).to be(false)
    end
  end

  describe "#limit_by_email_recipient_address" do
    before do
      allow(SiteConfig).to receive(:rate_limit_email_recipient).and_return(1)
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
