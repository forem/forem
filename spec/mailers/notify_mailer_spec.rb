require "rails_helper"

RSpec.describe NotifyMailer do
  let(:user)      { create(:user) }
  let(:user2)     { create(:user) }
  let(:article)   { create(:article, user_id: user.id) }
  let(:organization) { create(:organization) }
  let(:organization_membership) { create(:organization_membership, user: user, organization: organization) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }

  describe "#new_reply_email" do
    let(:email) { described_class.with(comment: comment).new_reply_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expected_subject = "#{comment.user.name} replied to your #{comment.parent_type}"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper receiver" do
      expect(email.to).to eq([comment.user.email])
    end
  end

  describe "#new_follower_email" do
    let(:email) { described_class.with(follow: user2.follows.last).new_follower_email }

    before { user2.follow(user) }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("#{user2.name} just followed you on #{Settings::Community.community_name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#new_mention_email" do
    context "when mentioning in a comment" do
      let(:comment_mention) { create(:mention, user: user2, mentionable: comment) }
      let(:email) { described_class.with(mention: comment_mention).new_mention_email }

      include_examples "#renders_proper_email_headers"

      it "renders proper subject and receiver", :aggregate_failures do
        expect(email.subject).to eq("#{comment.user.name} just mentioned you in their comment")
        expect(email.to).to eq([user2.email])
      end
    end

    context "when mentioning in an article" do
      let(:article_mention) { create(:mention, user: user2, mentionable: article) }
      let(:email) { described_class.with(mention: article_mention).new_mention_email }

      include_examples "#renders_proper_email_headers"

      it "renders proper subject and receiver", :aggregate_failures do
        expect(email.subject).to eq("#{article.user.name} just mentioned you in their post")
        expect(email.to).to eq([user2.email])
      end
    end
  end

  describe "#unread_notifications_email" do
    let(:email) { described_class.with(user: user).unread_notifications_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("🔥 You have 0 unread notifications on #{Settings::Community.community_name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#video_upload_complete_email" do
    let(:email) { described_class.with(article: article).video_upload_complete_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Your video upload is complete")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([article.user.email])
    end
  end

  describe "#new_badge_email" do
    let(:badge) { create(:badge) }
    let(:badge_achievement) { create_badge_achievement(user, badge, user2) }
    let(:email) { described_class.with(badge_achievement: badge_achievement).new_badge_email }

    let(:badge_with_credits) { create(:badge, credits_awarded: 7) }
    let(:badge_achievement_with_credits) { create_badge_achievement(user, badge_with_credits, user2) }
    let(:email_with_credits) { described_class.with(badge_achievement: badge_achievement_with_credits).new_badge_email }

    def create_badge_achievement(user, badge, rewarder)
      BadgeAchievement.create(
        user: user,
        badge: badge,
        rewarder: rewarder,
        rewarding_context_message_markdown: "Hello [Yoho](/hey)",
      )
    end

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("You just got a badge")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    context "when rendering the HTML email for badge with credits" do
      it "includes the listings URL" do
        expect(email_with_credits.html_part.body).to include(
          Rails.application.routes.url_helpers.listings_url(host: Settings::General.app_domain),
        )
      end

      it "includes the about listings URL" do
        expect(email_with_credits.html_part.body).to include(
          Rails.application.routes.url_helpers.about_listings_url(host: Settings::General.app_domain),
        )
      end

      it "includes number of credits" do
        expect(email_with_credits.html_part.body).to include("7 new credits")
      end
    end

    context "when rendering the text email for badge with credits" do
      it "includes the listings URL" do
        expect(email_with_credits.text_part.body).not_to include(
          CGI.escape(
            Rails.application.routes.url_helpers.listings_url(host: Settings::General.app_domain),
          ),
        )
      end

      it "includes the about listings URL" do
        expect(email_with_credits.text_part.body).not_to include(
          CGI.escape(Rails.application.routes.url_helpers.about_listings_url(host: Settings::General.app_domain)),
        )
      end

      it "includes number of credits" do
        expect(email_with_credits.text_part.body).to include("7 new credits")
      end
    end

    context "when rendering the HTML email for badge w/o credits" do
      it "includes the user URL" do
        expect(email.html_part.body).to include(URL.user(user))
      end

      it "doesn't include the listings URL" do
        expect(email.html_part.body).not_to include(
          CGI.escape(
            Rails.application.routes.url_helpers.listings_url(host: Settings::General.app_domain),
          ),
        )
      end

      it "doesn't include the about listings URL" do
        expect(email.html_part.body).not_to include(
          CGI.escape(Rails.application.routes.url_helpers.about_listings_url(host: Settings::General.app_domain)),
        )
      end

      it "includes the rewarding_context_message in the email" do
        expect(email.html_part.body).to include("Hello <a")
        expect(email.html_part.body).to include(URL.url("/hey"))
      end

      it "does not include the nil rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return(nil)

        expect(email.html_part.body).not_to include("Hello <a")
        expect(email.html_part.body).not_to include(URL.url("/hey"))
      end

      it "does not include the empty rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return("")

        expect(email.html_part.body).not_to include("Hello <a")
        expect(email.html_part.body).not_to include(URL.url("/hey"))
      end
    end

    context "when rendering the text email" do
      it "includes the user URL" do
        expect(email.text_part.body).to include(URL.user(user))
      end

      it "doesn't include the listings URL" do
        expect(email.text_part.body).not_to include(
          Rails.application.routes.url_helpers.listings_url(host: Settings::General.app_domain),
        )
      end

      it "doesn't include the about listings URL" do
        expect(email.text_part.body).not_to include(
          Rails.application.routes.url_helpers.about_listings_url(host: Settings::General.app_domain),
        )
      end

      it "includes the rewarding_context_message in the email" do
        expect(email.text_part.body).to include("Hello Yoho")
        expect(email.text_part.body).not_to include(URL.url("/hey"))
      end

      it "does not include the nil rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return(nil)

        expect(email.text_part.body).not_to include("Hello Yoho")
        expect(email.text_part.body).not_to include(URL.url("/hey"))
      end

      it "does not include the empty rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return("")

        expect(email.text_part.body).not_to include("Hello Yoho")
        expect(email.text_part.body).not_to include(URL.url("/hey"))
      end
    end
  end

  describe "#feedback_message_resolution_email" do
    let(:feedback_message) { create(:feedback_message, :abuse_report, reporter_id: user.id) }
    let(:email_params) do
      {
        email_to: user.email,
        email_subject: "#{Settings::Community.community_name} Report Status Update",
        email_body: "You've violated our code of conduct",
        email_type: "Reporter",
        feedback_message_id: feedback_message.id
      }
    end
    let(:email) { described_class.with(email_params).feedback_message_resolution_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("#{Settings::Community.community_name} Report Status Update")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "tracks the feedback message ID after delivery" do
      user # Instantiate user to pre-generate welcome email
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      assert_emails 1 do
        email.deliver_now
      end

      expect(user.email_messages.last.feedback_message_id).to eq(feedback_message.id)
    end

    it "tracks the email_type as the UTM campaign" do
      user # Instantiate user to pre-generate welcome email
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
      assert_emails 1 do
        email.deliver_now
      end

      expect(user.email_messages.last.utm_campaign).to eq("Reporter")
    end
  end

  describe "#feedback_response_email" do
    let(:email) { described_class.with(email_to: user.email).feedback_response_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Thanks for your report on #{Settings::Community.community_name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    it "renders proper body" do
      expect(email.html_part.body).to include("Thank you for flagging content")
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
    let(:email) { described_class.with(email_params).user_contact_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Buddy")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#account_deleted_email" do
    let(:email) { described_class.with(name: user.name, email: user.email).account_deleted_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("#{Settings::Community.community_name} - Account Deletion Confirmation")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#organization_deleted_email" do
    let(:email) do
      described_class.with(name: user.name, email: user.email, org_name: organization.name).organization_deleted_email
    end

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("#{Settings::Community.community_name} - Organization Deletion Confirmation")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#export_email" do
    let(:email) { described_class.with(email: user.email, attachment: "attachment").export_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to include("export of your content is ready")
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
  end

  describe "#tag_moderator_confirmation_email" do
    let(:tag) { create(:tag) }
    let(:email) do
      described_class.with(user: user, tag: tag, channel_slug: "javascript-4l67").tag_moderator_confirmation_email
    end

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Congrats! You're the moderator for ##{tag.name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end

  describe "#trusted_role_email" do
    let(:tag) { create(:tag) }
    let(:email) { described_class.with(user: user).trusted_role_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expected_subject = "Congrats! You're now a \"trusted\" user on #{Settings::Community.community_name}!"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end
  end
end
