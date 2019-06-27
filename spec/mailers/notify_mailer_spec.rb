require "rails_helper"

RSpec.describe NotifyMailer, type: :mailer do
  let(:user)      { create(:user) }
  let(:user2)     { create(:user) }
  let(:article)   { create(:article, user_id: user.id) }
  let(:comment)   { create(:comment, user_id: user.id, commentable_id: article.id) }

  describe "#new_reply_email" do
    it "renders proper subject" do
      email = described_class.new_reply_email(comment)
      expected_subject = "#{comment.user.name} replied to your #{comment.parent_type}"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper receiver" do
      email = described_class.new_reply_email(comment)
      expect(email.to).to eq([comment.user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_reply_email(comment)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_reply_email(comment)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_reply_email"))
    end
  end

  describe "#new_follower_email" do
    before { user2.follow(user) }

    it "renders proper subject" do
      email = described_class.new_follower_email(user2.follows.last)
      expect(email.subject).to eq("#{user2.name} just followed you on dev.to")
    end

    it "renders proper receiver" do
      email = described_class.new_follower_email(user2.follows.last)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_follower_email(user2.follows.last)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_follower_email(user2.follows.last)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_follower_email"))
    end
  end

  describe "#new_mention_email" do
    let(:mention) { create(:mention, user_id: user2.id, mentionable: comment) }

    it "renders proper subject" do
      email = described_class.new_mention_email(mention)
      expect(email.subject).to eq("#{comment.user.name} just mentioned you!")
    end

    it "renders proper receiver" do
      email = described_class.new_mention_email(mention)
      expect(email.to).to eq([user2.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_mention_email(mention)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_mention_email(mention)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_mention_email"))
    end
  end

  describe "#unread_notifications_email" do
    it "renders proper subject" do
      email = described_class.unread_notifications_email(user)
      expect(email.subject).to eq("🔥 You have 0 unread notifications on dev.to")
    end

    it "renders proper receiver" do
      email = described_class.unread_notifications_email(user)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.unread_notifications_email(user)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.unread_notifications_email(user)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=unread_notifications_email"))
    end
  end

  describe "#video_upload_complete_email" do
    it "renders proper subject" do
      email = described_class.video_upload_complete_email(article)
      expect(email.subject).to eq("Your video upload is complete")
    end

    it "renders proper receiver" do
      email = described_class.video_upload_complete_email(article)
      expect(email.to).to eq([article.user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.video_upload_complete_email(article)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.video_upload_complete_email(article)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=video_upload_complete_email"))
    end
  end

  describe "#new_badge_email" do
    let(:badge) { create(:badge) }
    let(:badge_achievement) { create_badge_achievement(user, badge, user2) }

    def create_badge_achievement(user, badge, rewarder)
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge.id,
        rewarder_id: rewarder.id,
        rewarding_context_message_markdown: "Hello [Yoho](/hey)",
      )
    end

    it "renders proper subject" do
      email = described_class.new_badge_email(badge_achievement)
      expect(email.subject).to eq("You just got a badge")
    end

    it "renders proper receiver" do
      email = described_class.new_badge_email(badge_achievement)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_badge_email(badge_achievement)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_badge_email(badge_achievement)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_badge_email"))
    end
  end

  describe "#feedback_message_resolution_email" do
    let(:feedback_message) { create(:feedback_message, :abuse_report, reporter_id: user.id) }

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
      email_params = params(user.email, feedback_message.id)
      email = described_class.feedback_message_resolution_email(email_params)
      expect(email.subject).to eq("DEV Report Status Update")
    end

    it "renders proper receiver" do
      email_params = params(user.email, feedback_message.id)
      email = described_class.feedback_message_resolution_email(email_params)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email_params = params(user.email, feedback_message.id)
      email = described_class.feedback_message_resolution_email(email_params)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email_params = params(user.email, feedback_message.id)
      email = described_class.feedback_message_resolution_email(email_params)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(
        CGI.escape("utm_campaign=#{email_params[:email_type]}"),
      )
    end

    it "tracks the feedback message ID after delivery" do
      email_params = params(user.email, feedback_message.id)
      email = described_class.feedback_message_resolution_email(email_params)

      assert_emails 1 do
        email.deliver_now
      end

      expect(user.email_messages.last.feedback_message_id).to eq(feedback_message.id)
    end
  end

  describe "#new_message_email" do
    let(:direct_channel) { ChatChannel.create_with_users([user, user2], "direct") }
    let(:direct_message) { create(:message, user: user, chat_channel: direct_channel) }

    it "renders proper subject" do
      email = described_class.new_message_email(direct_message)
      expect(email.subject).to eq("#{user.name} just messaged you")
    end

    it "renders proper receiver" do
      email = described_class.new_message_email(direct_message)
      expect(email.to).to eq([direct_message.direct_receiver.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_message_email(direct_message)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_message_email(direct_message)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_message_email"))
    end
  end

  describe "#account_deleted_email" do
    it "renders proper subject" do
      email = described_class.account_deleted_email(user)
      expect(email.subject).to eq("dev.to - Account Deletion Confirmation")
    end

    it "renders proper receiver" do
      email = described_class.account_deleted_email(user)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.account_deleted_email(user)
      expect(email.html_part.body).to include("open.gif")
    end

    it "does not include UTM params" do
      email = described_class.account_deleted_email(user)
      expect(email.html_part.body).not_to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).not_to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).not_to include(CGI.escape("utm_campaign=account_deleted_email"))
    end
  end

  describe "#export_email" do
    it "renders proper subject" do
      email = described_class.export_email(user, "attachment")
      expect(email.subject).to include("export of your content is ready")
    end

    it "renders proper receiver" do
      email = described_class.export_email(user, "attachment")
      expect(email.to).to eq([user.email])
    end

    it "attaches a zip file" do
      email = described_class.export_email(user, "attachment")
      expect(email.attachments[0].content_type).to include("application/zip")
    end

    it "adds the correct filename" do
      email = described_class.export_email(user, "attachment")
      expected_filename = "devto-export-#{Date.current.iso8601}.zip"
      expect(email.attachments[0].filename).to eq(expected_filename)
    end

    it "includes the tracking pixel" do
      email = described_class.export_email(user, "attachment")
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.export_email(user, "attachment")
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=export_email"))
    end
  end

  describe "#tag_moderator_confirmation_email" do
    let(:tag) { create(:tag) }

    it "renders proper subject" do
      email = described_class.tag_moderator_confirmation_email(user, tag.name)
      expect(email.subject).to eq("Congrats! You're the moderator for ##{tag.name}")
    end

    it "renders proper receiver" do
      email = described_class.tag_moderator_confirmation_email(user, tag.name)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.tag_moderator_confirmation_email(user, tag.name)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.tag_moderator_confirmation_email(user, tag.name)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=tag_moderator_confirmation_email"))
    end
  end
end
