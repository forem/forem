require "rails_helper"

RSpec.describe NotifyMailer, :type => :mailer do
  describe "notify" do
    let(:user)      { create(:user) }
    let(:user2)     { create(:user) }
    let(:article)   { create(:article, user_id: user.id) }
    let(:comment)   { create(:comment, user_id: user.id, commentable_id: article.id) }

    describe "new_reply_email" do
      it "renders proper subject" do
        new_reply_email = NotifyMailer.new_reply_email(comment)
        expect(new_reply_email.subject).to include("replied to your")
      end
      it "renders proper receiver" do
        new_reply_email = NotifyMailer.new_reply_email(comment)
        expect(new_reply_email.to).to eq([comment.user.email])
      end
    end

    describe "new_follower_email" do
      it "renders proper subject" do
        user2.follow(user)
        new_follower_email = NotifyMailer.new_follower_email(Follow.last)
        expect(new_follower_email.subject).to eq("#{user2.name} just followed you on dev.to")
      end
      it "renders proper receiver" do
        user2.follow(user)
        new_follower_email = NotifyMailer.new_follower_email(Follow.last)
        expect(new_follower_email.to).to eq([user.email])
      end
    end
    describe "new_mention_email" do
      it "renders proper subject" do
        mention = create(:mention, user_id: user2.id, mentionable_id: comment.id)
        new_mention_email = NotifyMailer.new_mention_email(mention)
        expect(new_mention_email.subject).to include("#{comment.user.name} just mentioned you")
      end
      it "renders proper receiver" do
        mention = create(:mention, user_id: user2.id, mentionable_id: comment.id)
        new_mention_email = NotifyMailer.new_mention_email(mention)
        expect(new_mention_email.to).to eq([user2.email])
      end
    end
    describe "new_membership_subscription_email" do
      it "renders proper subject" do
        user = create(:user)
        new_membership_subscription_email = NotifyMailer.new_membership_subscription_email(user,"level_1_member")
        expect(new_membership_subscription_email.subject).to include("Thanks for subscribing")
      end
      it "renders proper receiver" do
        user = create(:user)
        new_membership_subscription_email = NotifyMailer.new_membership_subscription_email(user,"level_1_member")
        expect(new_membership_subscription_email.to).to eq([user.email])
      end
    end
    describe "subscription_cancellation_email" do
      it "renders proper subject" do
        user = create(:user)
        subscription_cancellation_email = NotifyMailer.subscription_cancellation_email(user)
        expect(subscription_cancellation_email.subject).to include("Sorry to lose you")
      end
      it "renders proper receiver" do
        user = create(:user)
        subscription_cancellation_email = NotifyMailer.subscription_cancellation_email(user)
        expect(subscription_cancellation_email.to).to eq([user.email])
      end
    end

    describe "scholarship_awarded_email" do
      it "renders proper subject" do
        user = create(:user)
        scholarship_awarded_email = NotifyMailer.scholarship_awarded_email(user)
        expect(scholarship_awarded_email.subject).to eq("Congrats on your DEV Scholarship!")
      end

      it "renders proper receiver" do
        user = create(:user)
        scholarship_awarded_email = NotifyMailer.scholarship_awarded_email(user)
        expect(scholarship_awarded_email.to).to eq([user.email])
      end
    end
  end
end
