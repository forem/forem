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

      it "marks as not ready if there isn't atleast 3 articles" do
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
  end

  describe "#should_receive_email?" do
    let(:periodic_email_digest_days) { 3 }

    before do
      Settings::General.periodic_email_digest = periodic_email_digest_days
      create(:ahoy_message, user_id: user.id, sent_at: sent_at, clicked_at: clicked_at)
    end

    context "when the user clicked the last email within the lookback period" do
      let(:sent_at) { 2.days.ago }
      let(:clicked_at) { 1.day.ago }

      it "returns true" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be true
      end
    end
  
    context "when the user has not received any emails" do
      let(:sent_at) { nil }
      let(:clicked_at) { nil }
  
      it "returns true" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be true
      end
    end
  
    context "when the last email was received outside the periodic email digest days" do
      let(:sent_at) { 4.days.ago }
      let(:clicked_at) { nil }
  
      it "returns true" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be true
      end
    end
  
    context "when the last email was received within the periodic email digest days without click" do
      let(:sent_at) { 2.days.ago }
      let(:clicked_at) { nil }
  
      it "returns false" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be false
      end
    end
  
    context "when the last email was received just before the periodic email digest days limit" do
      let(:sent_at) { 3.days.ago }
      let(:clicked_at) { nil }
  
      it "returns true because it exactly matches the edge of the period" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be true
      end
    end
  
    context "when the last email was clicked but outside the lookback period" do
      let(:sent_at) { 31.days.ago }
      let(:clicked_at) { 30.days.ago }
  
      it "returns true because the click is too old to affect eligibility" do
        collector = described_class.new(user)
        expect(collector.should_receive_email?).to be true
      end
    end
  end
end
