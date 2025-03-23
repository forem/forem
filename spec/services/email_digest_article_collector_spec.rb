require "rails_helper"

RSpec.describe EmailDigestArticleCollector, type: :service do
  let(:user) { create(:user) }

  describe "#articles_to_send" do
    context "when user is brand new with no-follow" do
      it "provides top 3 articles" do
        create_list(:article, 3, public_reactions_count: 40, featured: true, score: 40)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(3)
      end

      it "marks as not ready if there isn't at least 3 articles" do
        create_list(:article, 2, public_reactions_count: 40, score: 40)
        articles = described_class.new(user).articles_to_send
        expect(articles).to be_empty
      end

      it "marks as not ready if there isn't at least 3 email-digest-eligible articles" do
        create_list(:article, 2, public_reactions_count: 40, score: 40)
        create_list(:article, 2, public_reactions_count: 40, email_digest_eligible: false)
        articles = described_class.new(user).articles_to_send
        expect(articles).to be_empty
      end
    end

    context "when the user has no follows, but does have a few pageviews" do
      it "provides featured 3 articles and articles tagged with their viewed articles" do
        user.page_views.create(article: create(:article, tag_list: "ruby"))
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40)
        create_list(:article, 2, tag_list: "ruby", public_reactions_count: 40, score: 40)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(4)
      end

      it "provides articles tagged with career in addition to featured and viewed" do
        user.page_views.create(article: create(:article, tag_list: "ruby"))
        create_list(:article, 2, public_reactions_count: 40, featured: true, score: 40)
        create_list(:article, 2, tag_list: "ruby", public_reactions_count: 40, score: 40)
        create_list(:article, 2, tag_list: "career", public_reactions_count: 40, score: 40)
        articles = described_class.new(user).articles_to_send
        expect(articles.length).to eq(6)
      end
    end

    context "when it's been less than the set number of digest email days" do
      before do
        author = create(:user)
        user.follow(author)
        user.update(following_users_count: 1)
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20)
        Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                             user_id: user.id, sent_at: Time.current.utc)
      end

      it "will return no articles when user shouldn't receive any" do
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
        create_list(:article, 3, user_id: author.id, public_reactions_count: 40, score: 40)
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
        articles = create_list(:article, 3, public_reactions_count: 40, score: 40)
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
        articles = create_list(:article, 5, public_reactions_count: 40, featured: true, score: 40)
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
        articles = create_list(:article, 5, public_reactions_count: 40, featured: true, score: 40)
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
