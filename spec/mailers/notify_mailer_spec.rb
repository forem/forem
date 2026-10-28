require "rails_helper"

RSpec.shared_examples "#delivers_via_smtp_by_default" do
  it "uses SMTP delivery when Customer.io is not configured" do
    expect(email.message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
  end
end

RSpec.describe NotifyMailer do
  let(:user)      { create(:user) }
  let(:user2)     { create(:user) }
  let(:article)   { create(:article, user_id: user.id) }
  let(:organization) { create(:organization) }
  let(:organization_membership) { create(:organization_membership, user: user, organization: organization) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }
  let(:token) { "secret" }

  describe "#new_reply_email" do
    let(:email) { described_class.with(comment: comment).new_reply_email }

    include_examples "#renders_proper_email_headers"
    include_examples "#renders_one_click_unsubscribe_headers"

    it "renders proper subject" do
      expected_subject = "#{comment.user.name} replied to your #{comment.parent_type}"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper receiver" do
      expect(email.to).to eq([comment.user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[comment.user])
        link_mlh_identity(comment.user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io new reply template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_new_reply_email")
        expect(settings[:message_data]["commenter_name"]).to eq(comment.user.name)
        expect(settings[:message_data]["parent_type"]).to eq(comment.parent_type)
        expect(settings[:message_data]["comment_html"]).to be_present
        expect(settings[:message_data]["comment_url"]).to eq(URL.comment(comment))
        expect(settings[:message_data]["article_or_parent_title"]).to eq(article.title)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
        expect(settings[:message_data]["unsubscribe_url"]).to include("ut=")
      end
    end
  end

  describe "#new_follower_email" do
    let(:email) { described_class.with(follow: user2.follows.last).new_follower_email }

    before { user2.follow(user) }

    include_examples "#renders_proper_email_headers"
    include_examples "#renders_one_click_unsubscribe_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("#{user2.name} just followed you on #{Settings::Community.community_name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io new follower template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_new_follower_email")
        expect(settings[:message_data]["follower_name"]).to eq(user2.name)
        expect(settings[:message_data]["follower_profile_url"]).to eq(URL.user(user2))
        expect(settings[:message_data]["follower_profile_image_url"]).to be_present
        expect(settings[:message_data]["followers_count"]).to eq(user.good_standing_followers_count)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
        expect(settings[:message_data]["unsubscribe_url"]).to include("ut=")
      end
    end
  end

  describe "#new_mention_email" do
    context "when mentioning in a comment" do
      let(:comment_mention) { create(:mention, user: user2, mentionable: comment) }
      let(:email) { described_class.with(mention: comment_mention).new_mention_email }

      include_examples "#renders_proper_email_headers"
      include_examples "#renders_one_click_unsubscribe_headers"

      it "renders proper subject and receiver", :aggregate_failures do
        expect(email.subject).to eq("#{comment.user.name} just mentioned you in their comment")
        expect(email.to).to eq([user2.email])
      end

      include_examples "#delivers_via_smtp_by_default"
    end

    context "when mentioning in an article" do
      let(:article_mention) { create(:mention, user: user2, mentionable: article) }
      let(:email) { described_class.with(mention: article_mention).new_mention_email }

      include_examples "#renders_proper_email_headers"
      include_examples "#renders_one_click_unsubscribe_headers"

      it "renders proper subject and receiver", :aggregate_failures do
        expect(email.subject).to eq("#{article.user.name} just mentioned you in their post")
        expect(email.to).to eq([user2.email])
      end
    end

    context "when routed through Customer.io" do
      let(:comment_mention) { create(:mention, user: user2, mentionable: comment) }
      let(:email) { described_class.with(mention: comment_mention).new_mention_email }

      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user2])
        link_mlh_identity(user2)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io new mention template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_new_mention_email")
        expect(settings[:message_data]["mentioner_name"]).to eq(comment.user.name)
        expect(settings[:message_data]["mentioner_profile_url"]).to eq(URL.user(comment.user))
        expect(settings[:message_data]["mentionable_type"]).to eq(comment_mention.decorate.formatted_mentionable_type)
        expected_mention_url = URL.url(comment_mention.mentionable.path, RequestStore.store[:subforem_domain])
        expect(settings[:message_data]["mention_url"]).to eq(expected_mention_url)
        expect(settings[:message_data]["comment_html"]).to eq(comment.processed_html)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
        expect(settings[:message_data]["unsubscribe_url"]).to include("ut=")
      end
    end
  end

  describe "#unread_notifications_email" do
    let(:email) { described_class.with(user: user).unread_notifications_email }

    include_examples "#renders_proper_email_headers"
    include_examples "#renders_one_click_unsubscribe_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("🔥 You have 0 unread notifications on #{Settings::Community.community_name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io unread notifications template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_unread_notifications_email")
        expect(settings[:message_data]["unread_count"]).to eq(0)
        expected_notifications_url = URL.url("/notifications", RequestStore.store[:subforem_domain])
        expect(settings[:message_data]["notifications_url"]).to eq(expected_notifications_url)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
        expect(settings[:message_data]["unsubscribe_url"]).to include("ut=")
      end
    end

    context "with subforem-specific user" do
      let!(:subforem) { create(:subforem, domain: "notify.example.com") }
      let(:subforem_community_name) { "Notify Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { described_class.with(user: user_with_subforem).unread_notifications_email }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      end

      it "uses subforem's community name in subject" do
        expect(email.subject).to eq("🔥 You have 0 unread notifications on #{subforem_community_name}")
      end

      it "uses subforem's domain in links" do
        expect(email.body.encoded).to include(subforem.domain)
      end
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

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[article.user])
        link_mlh_identity(article.user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io video upload complete template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_video_upload_complete")
        expect(settings[:message_data]["article_title"]).to eq(article.title)
        expect(settings[:message_data]["article_url"]).to eq("#{URL.article(article)}/edit")
      end
    end
  end

  describe "#gem_received_email" do
    let(:leader) { create(:user, :community_leader_level_1) }
    let(:email) { described_class.with(favoritable: article).gem_received_email }

    before { article.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current) }

    include_examples "#renders_proper_email_headers"
    include_examples "#renders_one_click_unsubscribe_headers"
    include_examples "#delivers_via_smtp_by_default"

    it "renders proper subject and receiver", :aggregate_failures do
      expect(email.subject).to eq("💎 Your post was picked as a gem")
      expect(email.to).to eq([user.email])
    end

    it "explains the gem and links to the post", :aggregate_failures do
      expect(email.html_part.body).to include("Gems are rare")
      expect(email.html_part.body).to include(CGI.escapeHTML(article.title))
      expect(email.text_part.body).to include(URL.article(article))
    end

    it "invites a regular member to pass a gem on", :aggregate_failures do
      expect(email.html_part.body).to include("You have a gem to give")
      expect(email.text_part.body).to include("Share the love!")
    end

    it "does not offer a gem to pass on to a community leader" do
      user.add_role(:community_leader_level_1)

      expect(email.html_part.body).not_to include("You have a gem to give")
    end

    it "does not offer a gem to pass on to a suspended author" do
      user.add_role(:suspended)

      expect(email.html_part.body).not_to include("You have a gem to give")
    end

    it "does not send when the author has turned off badge emails" do
      user.notification_setting.update!(email_badge_notifications: false)

      expect(email.message).to be_a(ActionMailer::Base::NullMail)
    end

    context "when the post belongs to a non-default subforem" do
      let!(:default_subforem) { create(:subforem, domain: "default.example.com") }
      let!(:gem_subforem) { create(:subforem, domain: "gems.example.com") }

      before do
        article.update_columns(subforem_id: gem_subforem.id)
        allow(Subforem).to receive_messages(
          cached_default_id: default_subforem.id,
          cached_default_domain: default_subforem.domain,
          cached_id_to_domain_hash: { default_subforem.id => default_subforem.domain,
                                      gem_subforem.id => gem_subforem.domain },
        )
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:community_name)
          .with(subforem_id: gem_subforem.id).and_return("Gem Community")
      end

      it "brands the email and links for the community where the gem was given", :aggregate_failures do
        expect(email[:from].display_names).to eq(["Gem Community"])
        expect(email.text_part.body).to include("more people on Gem Community find it")
        expect(email.text_part.body).to include("The Gem Community Team")
        expect(email.text_part.body).to include("#{URL.protocol}gems.example.com/\n")
        # Ahoy wraps links for click tracking, so check the wrapped target.
        expect(email.html_part.body).to include("u=#{CGI.escape("#{URL.protocol}gems.example.com/")}\"")
        expect(email.html_part.body).not_to include("default.example.com")
      end
    end

    context "when the favorite is a comment" do
      let(:email) { described_class.with(favoritable: comment).gem_received_email }

      before { comment.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current) }

      it "describes the comment and links to it", :aggregate_failures do
        expect(email.subject).to eq("💎 Your comment was picked as a gem")
        expect(email.text_part.body).to include("your comment on \"#{article.title}\"")
        expect(email.text_part.body).to include(URL.comment(comment))
      end
    end

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "sends the Forem-rendered body instead of a Customer.io template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(email.message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
        expect(settings[:transactional_message_id]).to be_nil
        expect(email.html_part.body).to include("Gems are rare")
      end
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
    include_examples "#renders_one_click_unsubscribe_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("You just got a badge")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io new badge template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_new_badge_email")
        expect(settings[:message_data]["badge_name"]).to eq(badge.title)
        expect(settings[:message_data]["badge_description"]).to eq(badge.description)
        expect(settings[:message_data]["badge_image_url"]).to eq(badge.badge_image_url)
        expect(settings[:message_data]["rewarding_context_message_html"])
          .to eq(badge_achievement.rewarding_context_message.presence)
        expect(settings[:message_data]["profile_url"]).to eq(URL.user(user))
        expect(settings[:message_data]["unsubscribe_url"]).to include("ut=")
      end
    end

    context "when rendering the HTML email for badge w/o credits" do
      it "includes the user URL" do
        expect(email.html_part.body).to include("/#{user.username}")
      end

      it "includes the click tracking parameters" do
        expect(email.html_part.body).to include("/hey?ahoy_click=true&t=")
      end

      it "includes the rewarding_context_message in the email" do
        expect(email.html_part.body).to include("Hello <a")
        expect(email.html_part.body).to include("/hey")
      end

      it "does not include the nil rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return(nil)

        expect(email.html_part.body).not_to include("Hello <a")
        expect(email.html_part.body).not_to include("/hey")
      end

      it "does not include the empty rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return("")

        expect(email.html_part.body).not_to include("Hello <a")
        expect(email.html_part.body).not_to include("/hey")
      end
    end

    context "when rendering the text email" do
      it "includes the user URL" do
        expect(email.text_part.body).to include(URL.user(user))
      end

      it "includes the rewarding_context_message in the email" do
        expect(email.text_part.body).to include("Hello Yoho")
        expect(email.text_part.body).not_to include("/hey")
      end

      it "does not include the nil rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return(nil)

        expect(email.text_part.body).not_to include("Hello Yoho")
        expect(email.text_part.body).not_to include("/hey")
      end

      it "does not include the empty rewarding_context_message in the email" do
        allow(badge_achievement).to receive(:rewarding_context_message).and_return("")

        expect(email.text_part.body).not_to include("Hello Yoho")
        expect(email.text_part.body).not_to include("/hey")
      end
    end

    context "when the rewarding_context_message includes internal and external links" do
      before do
        allow(badge_achievement).to receive(:rewarding_context_message_markdown).and_return(
          "Hello [Internal Link](/internal-path) and [External Link](https://externaldomain.com/path)",
        )
        badge_achievement.save!
      end

      it "processes internal links correctly in the HTML email" do
        doc = Nokogiri::HTML(email.html_part.body.to_s)
        internal_link = doc.at_xpath("//a[contains(text(), 'Internal Link')]")
        expect(internal_link).not_to be_nil
        href = internal_link["href"]
        expect(href).to include("/internal-path")
        expect(href).to include("ahoy_click=true")
        expect(href).to include("t=")
        expect(href).to include("s=")
        expect(href).to include("u=")
        expect(href).not_to include("/ahoy/click")
      end

      it "processes external links correctly in the HTML email" do
        doc = Nokogiri::HTML(email.html_part.body.to_s)
        external_link = doc.at_xpath("//a[contains(text(), 'External Link')]")
        expect(external_link).not_to be_nil
        href = external_link["href"]
        expect(href).to include("/ahoy/click")
        expect(href).to include("t=")
        expect(href).to include("s=")
        expect(href).to include("u=")
        expect(href).to include(CGI.escape("https://externaldomain.com/path"))
        expect(href).not_to eq("https://externaldomain.com/path")
      end

      it "does not add UTM parameters to internal links" do
        doc = Nokogiri::HTML(email.html_part.body.to_s)
        internal_link = doc.at_xpath("//a[contains(text(), 'Internal Link')]")
        href = internal_link["href"]
        uri = Addressable::URI.parse(href)
        query_params = uri.query_values || {}
        expect(query_params.keys).not_to include("utm_source", "utm_medium", "utm_campaign")
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

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io feedback resolution template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_feedback_resolution")
        expect(settings[:message_data]["email_body"]).to eq("You've violated our code of conduct")
      end
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

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io feedback response template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_feedback_response")
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
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

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io user contact template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_user_contact")
        expect(settings[:message_data]["email_body"]).to eq("Laugh with me, buddy")
      end
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

    it "includes contact email" do
      expect(email.html_part.body).to include(ForemInstance.contact_email)
    end

    context "with subforem-specific user" do
      let!(:subforem) { create(:subforem, domain: "deleted.example.com") }
      let(:subforem_community_name) { "Deleted Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { described_class.with(name: user_with_subforem.name, email: user_with_subforem.email).account_deleted_email }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:community_name).with(no_args).and_return(subforem_community_name)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      end

      it "uses subforem's community name in subject" do
        expect(email.subject).to eq("#{subforem_community_name} - Account Deletion Confirmation")
      end

      it "uses subforem's community name in email body" do
        expect(email.body.encoded).to include(subforem_community_name)
      end
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io account deleted template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_account_deleted")
        expect(settings[:message_data]["name"]).to eq(user.name)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
    end
  end

  describe "#account_deletion_requested_email" do
    let(:email) do
      described_class.with(user: user, token: token).account_deletion_requested_email
    end

    include_examples "#renders_proper_email_headers"

    it "includes contact email" do
      expect(email.html_part.body).to include(ForemInstance.contact_email)
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io account deletion requested template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_account_deletion_requested")
        expect(settings[:message_data]["name"]).to eq(user.name)
        expect(settings[:message_data]["confirmation_url"]).to include(token)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
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

    it "includes contact email" do
      expect(email.html_part.body).to include(ForemInstance.contact_email)
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io organization deleted template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_organization_deleted")
        expect(settings[:message_data]["name"]).to eq(user.name)
        expect(settings[:message_data]["org_name"]).to eq(organization.name)
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
    end
  end

  describe "#export_email" do
    let(:email) { described_class.with(email: user.email, attachment: "attachment").export_email }

    include_examples "#renders_proper_email_headers"

    it "does not render one-click unsubscribe headers on transactional mail", :aggregate_failures do
      expect(email["List-Unsubscribe"]).to be_nil
      expect(email["List-Unsubscribe-Post"]).to be_nil
    end

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

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io export template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_export_email")
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end

      it "still attaches the zip file on the mail object" do
        expect(email.attachments[0].content_type).to include("application/zip")
        expected_filename = "devto-export-#{Date.current.iso8601}.zip"
        expect(email.attachments[0].filename).to eq(expected_filename)
      end
    end
  end

  describe "#tag_moderator_confirmation_email" do
    let(:tag) { create(:tag) }
    let(:email) do
      described_class.with(user: user, tag: tag, channel_slug: "javascript-4l67").tag_moderator_confirmation_email
    end

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Congrats! You're now a moderator for ##{tag.name}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io tag moderator confirmation template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_tag_mod_confirmation")
        expect(settings[:message_data]["tag_name"]).to eq(tag.name)
        expect(settings[:message_data]["tag_url"]).to eq(URL.tag(tag))
        expect(settings[:message_data]["community_moderation_url"]).to be_present
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
    end
  end

  describe "#subforem_moderator_confirmation_email" do
    let(:subforem) { create(:subforem, domain: "modsubforem.example.com") }
    let(:email) do
      described_class.with(user: user, subforem: subforem).subforem_moderator_confirmation_email
    end

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expect(email.subject).to eq("Congrats! You're now a moderator for #{subforem.domain}")
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io subforem moderator confirmation template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_subforem_mod_confirmation")
        expect(settings[:message_data]["subforem_domain"]).to eq(subforem.domain)
        expect(settings[:message_data]["subforem_url"]).to eq("https://#{subforem.domain}")
        expect(settings[:message_data]["community_moderation_url"]).to be_present
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
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

    context "with subforem-specific user" do
      let!(:subforem) { create(:subforem, domain: "trusted.example.com") }
      let(:subforem_community_name) { "Trusted Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { described_class.with(user: user_with_subforem).trusted_role_email }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:community_name).with(no_args).and_return(subforem_community_name)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      end

      it "uses subforem's community name in subject" do
        expected_subject = "Congrats! You're now a \"trusted\" user on #{subforem_community_name}!"
        expect(email.subject).to eq(expected_subject)
      end

      it "uses subforem's domain in links" do
        expect(email.body.encoded).to include(subforem.domain)
      end
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io trusted role template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_trusted_role")
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
        expect(settings[:message_data]).to have_key("trusted_member_guide_url")
      end
    end

    context "when routed through Customer.io with a trusted-member Page" do
      before do
        create(:page, slug: "trusted-member")
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "includes the guide URL" do
        settings = email.message.delivery_method.settings

        expect(settings[:message_data]["trusted_member_guide_url"]).to include("trusted-member")
      end
    end
  end

  describe "#base_subscriber_role_email" do
    let(:email) { described_class.with(user: user).base_subscriber_role_email }

    include_examples "#renders_proper_email_headers"

    it "renders proper subject" do
      expected_subject = "Congrats! You're now subscribed to DEV++"
      expect(email.subject).to eq(expected_subject)
    end

    it "renders proper receiver" do
      expect(email.to).to eq([user.email])
    end

    context "with subforem-specific user" do
      let!(:subforem) { create(:subforem, domain: "subscriber.example.com") }
      let(:subforem_community_name) { "Subscriber Community" }
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { described_class.with(user: user_with_subforem).base_subscriber_role_email }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
        allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
        allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      end

      it "uses subforem's domain in links" do
        expect(email.body.encoded).to include(subforem.domain)
      end
    end

    include_examples "#delivers_via_smtp_by_default"

    context "when routed through Customer.io" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
        link_mlh_identity(user)
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io base subscriber role template", :aggregate_failures do
        settings = email.message.delivery_method.settings

        expect(settings[:transactional_message_id]).to eq("dev_base_subscriber_role")
        expect(settings[:message_data]["community_name"]).to eq(Settings::Community.community_name)
      end
    end
  end
end
