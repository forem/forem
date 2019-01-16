require "rails_helper"

RSpec.describe NotifyMailer, type: :mailer do
  describe "notify" do
    let(:user)      { create(:user) }
    let(:user2)     { create(:user) }
    let(:article)   { create(:article, user_id: user.id) }
    let(:comment)   { create(:comment, user_id: user.id, commentable_id: article.id) }

    describe "#new_reply_email" do
      it "renders proper subject" do
        new_reply_email = described_class.new_reply_email(comment)
        expect(new_reply_email.subject).to include("replied to your")
      end

      it "renders proper receiver" do
        new_reply_email = described_class.new_reply_email(comment)
        expect(new_reply_email.to).to eq([comment.user.email])
      end
    end

    describe "#new_follower_email" do
      it "renders proper subject" do
        user2.follow(user)
        new_follower_email = described_class.new_follower_email(Follow.last)
        expect(new_follower_email.subject).to eq("#{user2.name} just followed you on dev.to")
      end

      it "renders proper receiver" do
        user2.follow(user)
        new_follower_email = described_class.new_follower_email(Follow.last)
        expect(new_follower_email.to).to eq([user.email])
      end
    end

    describe "#new_mention_email" do
      it "renders proper subject" do
        mention = create(:mention, user_id: user2.id, mentionable_id: comment.id)
        new_mention_email = described_class.new_mention_email(mention)
        expect(new_mention_email.subject).to include("#{comment.user.name} just mentioned you")
      end

      it "renders proper receiver" do
        mention = create(:mention, user_id: user2.id, mentionable_id: comment.id)
        new_mention_email = described_class.new_mention_email(mention)
        expect(new_mention_email.to).to eq([user2.email])
      end
    end

    describe "#new_badge_email" do
      let(:badge) { create(:badge) }

      def create_badge_achievement(user, badge, rewarder)
        BadgeAchievement.create(
          user_id: user.id,
          badge_id: badge.id,
          rewarder_id: rewarder.id,
          rewarding_context_message_markdown: "Hello [Yoho](/hey)",
        )
      end

      it "renders proper subject" do
        badge_achievement = create_badge_achievement(user, badge, user2)
        new_badge_email = described_class.new_badge_email(badge_achievement)
        expect(new_badge_email.subject).to eq("You just got a badge")
      end

      it "renders proper receiver" do
        badge_achievement = create_badge_achievement(user, badge, user2)
        new_badge_email = described_class.new_badge_email(badge_achievement)
        expect(new_badge_email.to).to eq([user.email])
      end
    end

    describe "#new_feedback_message_resolution_email" do
      def params(user_email, feedback_message_id)
        {
          email_to: user_email,
          email_subject: "DEV Report Status Update",
          email_body: "You've violated our code of conduct",
          email_type: "Reporter",
          feedback_message_id: feedback_message_id
        }
      end

      it "renders proper subject" do
        feedback_message = create(:feedback_message, :abuse_report, reporter_id: user.id)
        feedback_message_resolution_email = described_class.
          feedback_message_resolution_email(params(user.email, feedback_message.id))
        expect(feedback_message_resolution_email.subject).to eq "DEV Report Status Update"
      end

      it "renders proper receiver" do
        feedback_message = create(:feedback_message, :abuse_report, reporter_id: user.id)
        feedback_message_resolution_email = described_class.
          feedback_message_resolution_email(params(user.email, feedback_message.id))
        expect(feedback_message_resolution_email.to).to eq [user.email]
      end
    end

    describe "#account_deleted_email" do
      let(:user) { create(:user) }

      it "renders proper subject" do
        account_deleted_email = described_class.account_deleted_email(user)
        expect(account_deleted_email.subject).to eq "dev.to - Account Deletion Confirmation"
      end

      it "renders proper receiver" do
        account_deleted_email = described_class.account_deleted_email(user)
        expect(account_deleted_email.to).to eq [user.email]
      end
    end

    describe "#mentee_email" do
      let(:mentee) { create(:user) }
      let(:mentor) { create(:user) }

      it "renders proper subject" do
        mentee_email = described_class.mentee_email(mentee, mentor)
        expect(mentee_email.subject).to eq "You have been matched with a DEV mentor!"
      end

      it "renders proper from" do
        mentee_email = described_class.mentee_email(mentee, mentor)
        expect(mentee_email.from).to include "liana@dev.to"
      end
    end

    describe "#mentor_email" do
      let(:mentee) { create(:user) }
      let(:mentor) { create(:user) }

      it "renders proper subject" do
        mentor_email = described_class.mentor_email(mentor, mentee)
        expect(mentor_email.subject).to eq "You have been matched with a new DEV mentee!"
      end

      it "renders proper from" do
        mentor_email = described_class.mentor_email(mentor, mentee)
        expect(mentor_email.from).to include "liana@dev.to"
      end
    end

    describe "#tag_moderator_confirmation_email" do
      let(:user) { create(:user) }
      let(:tag) { create(:tag) }

      it "renders proper subject" do
        moderator_email = described_class.tag_moderator_confirmation_email(user, tag.name)
        expect(moderator_email.subject).to eq "Congrats! You're the moderator for ##{tag.name}"
      end
    end

    describe "#export_email" do
      it "renders proper subject" do
        export_email = described_class.export_email(user, "attachment")
        expect(export_email.subject).to include("export of your data is ready")
      end

      it "renders proper receiver" do
        export_email = described_class.export_email(user, "attachment")
        expect(export_email.to).to eq([user.email])
      end

      it "attaches a zip file" do
        export_email = described_class.export_email(user, "attachment")
        expect(export_email.attachments[0].content_type).to include("application/zip")
      end

      it "adds the correct filename" do
        export_email = described_class.export_email(user, "attachment")
        expected_filename = "devto-export-#{Date.current.iso8601}.zip"
        expect(export_email.attachments[0].filename).to eq(expected_filename)
      end
    end
  end
end
