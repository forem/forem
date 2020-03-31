require "rails_helper"

RSpec.describe NotifyMailer, type: :mailer do
  let(:user)      { create(:user) }
  let(:user2)     { create(:user) }
  let(:article)   { create(:article, user_id: user.id) }
  let(:comment)   { create(:comment, user_id: user.id, commentable: article) }

  describe "#new_reply_email" do
    let(:email) { described_class.new_reply_email(comment) }

    it "renders proper subject" do
      expected_subject = "#{comment.user.name} replied to your #{comment.parent_type}"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([comment.user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_reply_email"))
    end
  end

  describe "#new_follower_email" do
    let(:email) { described_class.new_follower_email(user2.follows.last) }

    before { user2.follow(user) }

    it "renders proper subject" do
      expect(email.subject).to eq("#{user2.name} just followed you on dev.to")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_follower_email"))
    end
  end

  describe "#new_mention_email" do
    let(:mention) { create(:mention, user: user2, mentionable: comment) }
    let(:email) { described_class.new_mention_email(mention) }

    it "renders proper subject" do
      expect(email.subject).to eq("#{comment.user.name} just mentioned you!")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user2.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_mention_email"))
    end
  end

  describe "#unread_notifications_email" do
    let(:email) { described_class.unread_notifications_email(user) }

    it "renders proper subject" do
      expect(email.subject).to eq("🔥 You have 0 unread notifications on dev.to")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=unread_notifications_email"))
    end
  end

  describe "#video_upload_complete_email" do
    let(:email) { described_class.video_upload_complete_email(article) }

    it "renders proper subject" do
      expect(email.subject).to eq("Your video upload is complete")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([article.user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=video_upload_complete_email"))
    end
  end

  describe "#new_badge_email" do
    let(:badge) { create(:badge) }
    let(:badge_achievement) { create_badge_achievement(user, badge, user2) }
    let(:email) { described_class.new_badge_email(badge_achievement) }

    def create_badge_achievement(user, badge, rewarder)
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge.id,
        rewarder_id: rewarder.id,
        rewarding_context_message_markdown: "Hello [Yoho](/hey)",
      )
    end

    it "renders proper subject" do
      expect(email.subject).to eq("You just got a badge")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_badge_email"))
    end
  end

  describe "#feedback_message_resolution_email" do
    let(:feedback_message) { create(:feedback_message, :abuse_report, reporter_id: user.id) }
    let(:email_params) do
      {
        email_to: user.email,
        email_subject: "DEV Report Status Update",
        email_body: "You've violated our code of conduct",
        email_type: "Reporter",
        feedback_message_id: feedback_message.id
      }
    end
    let(:email) { described_class.feedback_message_resolution_email(email_params) }

    it "renders proper subject" do
      expect(email.subject).to eq("DEV Report Status Update")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=#{email_params[:email_type]}"))
    end

    it "tracks the feedback message ID after delivery" do
      assert_emails 1 do
        email.deliver_now
      end

      expect(user.email_messages.last.feedback_message_id).to eq(feedback_message.id)
    end
  end

  describe "#user_contact_email" do
    let(:email_params) do
      {
        user_id: user.id,
        email_subject: "Buddy",
        email_body: "Laugh with me, buddy"
      }
    end
    let(:email) { described_class.user_contact_email(email_params) }

    it "renders proper subject" do
      expect(email.subject).to eq("Buddy")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=user_contact"))
    end
  end

  describe "#new_message_email" do
    let(:direct_channel) { ChatChannel.create_with_users([user, user2], "direct") }
    let(:direct_message) { create(:message, user: user, chat_channel: direct_channel) }
    let(:email) { described_class.new_message_email(direct_message) }

    it "renders proper subject" do
      expect(email.subject).to eq("#{user.name} just messaged you")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([direct_message.direct_receiver.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_message_email"))
    end
  end

  describe "#account_deleted_email" do
    let(:email) { described_class.account_deleted_email(user) }

    it "renders proper subject" do
      expect(email.subject).to eq("dev.to - Account Deletion Confirmation")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "does not include UTM params" do
      expect(email.html_part.body).not_to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).not_to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).not_to include(CGI.escape("utm_campaign=account_deleted_email"))
    end
  end

  describe "#export_email" do
    let(:email) { described_class.export_email(user, "attachment") }

    it "renders proper subject" do
      expect(email.subject).to include("export of your content is ready")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "attaches a zip file" do
      expect(email.attachments[0].content_type).to include("application/zip")
    end

    it "adds the correct filename" do
      expected_filename = "devto-export-#{Date.current.iso8601}.zip"
      expect(email.attachments[0].filename).to eq(expected_filename)
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=export_email"))
    end
  end

  describe "#tag_moderator_confirmation_email" do
    let(:tag) { create(:tag) }
    let(:email) { described_class.tag_moderator_confirmation_email(user, tag.name) }

    it "renders proper subject" do
      expect(email.subject).to eq("Congrats! You're the moderator for ##{tag.name}")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=tag_moderator_confirmation_email"))
    end
  end

  describe "#trusted_role_email" do
    let(:tag) { create(:tag) }
    let(:email) { described_class.trusted_role_email(user) }

    it "renders proper subject" do
      expect(email.subject).to eq("You've been upgraded to #{ApplicationConfig['COMMUNITY_NAME']} Community mod status!")
    end

    it "renders proper sender" do
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Community <#{SiteConfig.default_site_email}>")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=notify_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=trusted_role_email"))
    end
  end
end
