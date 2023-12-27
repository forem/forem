require "rails_helper"

RSpec.describe User do
  def user_from_authorization_service(service_name, signed_in_resource = nil, cta_variant = "navbar_basic")
    auth = OmniAuth.config.mock_auth[service_name]
    Authentication::Authenticator.call(
      auth,
      current_user: signed_in_resource,
      cta_variant: cta_variant,
    )
  end

  def mock_username(provider_name, username)
    case provider_name
    when :apple
      OmniAuth.config.mock_auth[provider_name].info.first_name = username
    when :forem
      OmniAuth.config.mock_auth[provider_name].info.user_nickname = username
    else
      OmniAuth.config.mock_auth[provider_name].info.nickname = username
    end
  end

  def provider_username(service_name)
    auth_payload = OmniAuth.config.mock_auth[service_name]
    provider_class = Authentication::Providers.get!(auth_payload.provider)
    provider_class.new(auth_payload).user_nickname
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:org) { create(:organization) }

  before do
    omniauth_mock_providers_payload
    allow(SegmentedUserRefreshWorker).to receive(:perform_async)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:admin?).to(:authorizer) }
    it { is_expected.to delegate_method(:any_admin?).to(:authorizer) }
    it { is_expected.to delegate_method(:auditable?).to(:authorizer) }
    it { is_expected.to delegate_method(:banished?).to(:authorizer) }
    it { is_expected.to delegate_method(:comment_suspended?).to(:authorizer) }
    it { is_expected.to delegate_method(:creator?).to(:authorizer) }
    it { is_expected.to delegate_method(:has_trusted_role?).to(:authorizer) }
    it { is_expected.to delegate_method(:podcast_admin_for?).to(:authorizer) }
    it { is_expected.to delegate_method(:restricted_liquid_tag_for?).to(:authorizer) }
    it { is_expected.to delegate_method(:single_resource_admin_for?).to(:authorizer) }
    it { is_expected.to delegate_method(:super_admin?).to(:authorizer) }
    it { is_expected.to delegate_method(:support_admin?).to(:authorizer) }
    it { is_expected.to delegate_method(:suspended?).to(:authorizer) }
    it { is_expected.to delegate_method(:spam?).to(:authorizer) }
    it { is_expected.to delegate_method(:spam_or_suspended?).to(:authorizer) }
    it { is_expected.to delegate_method(:tag_moderator?).to(:authorizer) }
    it { is_expected.to delegate_method(:tech_admin?).to(:authorizer) }
    it { is_expected.to delegate_method(:trusted?).to(:authorizer) }
    it { is_expected.to delegate_method(:user_subscription_tag_available?).to(:authorizer) }
    it { is_expected.to delegate_method(:vomited_on?).to(:authorizer) }
    it { is_expected.to delegate_method(:warned?).to(:authorizer) }
  end

  describe "validations" do
    describe "builtin validations" do
      subject { user }

      it { is_expected.to have_one(:profile).dependent(:delete) }
      it { is_expected.to have_one(:notification_setting).dependent(:delete) }
      it { is_expected.to have_one(:setting).dependent(:delete) }

      it { is_expected.to have_many(:ahoy_events).class_name("Ahoy::Event").dependent(:delete_all) }
      it { is_expected.to have_many(:ahoy_visits).class_name("Ahoy::Visit").dependent(:delete_all) }
      it { is_expected.to have_many(:api_secrets).dependent(:delete_all) }
      it { is_expected.to have_many(:articles).dependent(:destroy) }
      it { is_expected.to have_many(:audit_logs).dependent(:nullify) }
      it { is_expected.to have_many(:badge_achievements).dependent(:delete_all) }
      it { is_expected.to have_many(:badges).through(:badge_achievements) }
      it { is_expected.to have_many(:collections).dependent(:destroy) }
      it { is_expected.to have_many(:comments).dependent(:destroy) }
      it { is_expected.to have_many(:credits).dependent(:destroy) }
      it { is_expected.to have_many(:discussion_locks).dependent(:delete_all) }
      it { is_expected.to have_many(:billboard_events).dependent(:nullify) }
      it { is_expected.to have_many(:email_authorizations).dependent(:delete_all) }
      it { is_expected.to have_many(:email_messages).class_name("Ahoy::Message").dependent(:destroy) }
      it { is_expected.to have_many(:feed_events).dependent(:nullify) }
      it { is_expected.to have_many(:field_test_memberships).class_name("FieldTest::Membership").dependent(:destroy) }
      it { is_expected.to have_many(:github_repos).dependent(:destroy) }
      it { is_expected.to have_many(:html_variants).dependent(:destroy) }
      it { is_expected.to have_many(:identities).dependent(:delete_all) }
      it { is_expected.to have_many(:identities_enabled) }
      it { is_expected.to have_many(:listings).dependent(:destroy) }
      it { is_expected.to have_many(:mentions).dependent(:delete_all) }
      it { is_expected.to have_many(:notes).dependent(:delete_all) }
      it { is_expected.to have_many(:notification_subscriptions).dependent(:delete_all) }
      it { is_expected.to have_many(:notifications).dependent(:delete_all) }
      it { is_expected.to have_many(:organization_memberships).dependent(:delete_all) }
      it { is_expected.to have_many(:organizations).through(:organization_memberships) }
      it { is_expected.to have_many(:page_views).dependent(:nullify) }
      it { is_expected.to have_many(:podcast_episode_appearances).dependent(:delete_all) }
      it { is_expected.to have_many(:podcast_episodes).through(:podcast_episode_appearances).source(:podcast_episode) }
      it { is_expected.to have_many(:podcast_ownerships).dependent(:delete_all) }
      it { is_expected.to have_many(:podcasts_owned).through(:podcast_ownerships).source(:podcast) }
      it { is_expected.to have_many(:poll_skips).dependent(:delete_all) }
      it { is_expected.to have_many(:poll_votes).dependent(:delete_all) }
      it { is_expected.to have_many(:profile_pins).dependent(:delete_all) }
      it { is_expected.to have_many(:rating_votes).dependent(:nullify) }
      it { is_expected.to have_many(:reactions).dependent(:destroy) }
      it { is_expected.to have_many(:response_templates).dependent(:delete_all) }
      it { is_expected.to have_many(:source_authored_user_subscriptions).dependent(:destroy) }
      it { is_expected.to have_many(:segmented_users).dependent(:destroy) }
      it { is_expected.to have_many(:audience_segments).through(:segmented_users) }
      it { is_expected.to have_many(:subscribed_to_user_subscriptions).dependent(:destroy) }
      it { is_expected.to have_many(:subscribers).dependent(:destroy) }
      it { is_expected.to have_many(:tweets).dependent(:nullify) }
      it { is_expected.to have_many(:languages).dependent(:delete_all) }

      # rubocop:disable RSpec/NamedSubject
      it do
        expect(subject).to have_many(:affected_feedback_messages)
          .class_name("FeedbackMessage")
          .with_foreign_key("affected_id")
          .dependent(:nullify)
      end

      it do
        expect(subject).to have_many(:authored_notes)
          .class_name("Note")
          .with_foreign_key("author_id")
          .dependent(:delete_all)
      end

      it do
        expect(subject).to have_many(:badge_achievements_rewarded)
          .class_name("BadgeAchievement")
          .with_foreign_key("rewarder_id")
          .inverse_of(:rewarder)
          .dependent(:nullify)
      end

      it do
        expect(subject).to have_many(:banished_users)
          .class_name("BanishedUser")
          .with_foreign_key("banished_by_id")
          .inverse_of(:banished_by)
          .dependent(:nullify)
      end

      it do
        expect(subject).to have_many(:blocked_blocks)
          .class_name("UserBlock")
          .with_foreign_key("blocked_id")
          .dependent(:delete_all)
      end

      it do
        expect(subject).to have_many(:blocker_blocks)
          .class_name("UserBlock")
          .with_foreign_key("blocker_id")
          .dependent(:delete_all)
      end

      it do
        expect(subject).to have_many(:created_podcasts)
          .class_name("Podcast")
          .with_foreign_key(:creator_id)
          .dependent(:nullify)
      end

      it do
        expect(subject).to have_many(:offender_feedback_messages)
          .class_name("FeedbackMessage")
          .with_foreign_key(:offender_id)
          .dependent(:nullify)
      end

      it do
        expect(subject).to have_many(:reporter_feedback_messages)
          .class_name("FeedbackMessage")
          .with_foreign_key(:reporter_id)
          .dependent(:nullify)
      end
      # rubocop:enable RSpec/NamedSubject

      it { is_expected.not_to allow_value("AcMe_1%").for(:username) }
      it { is_expected.to allow_value("AcMe_1").for(:username) }

      it { is_expected.not_to allow_value("$example.com/value\x1F").for(:payment_pointer) }
      it { is_expected.not_to allow_value("example.com/value").for(:payment_pointer) }
      it { is_expected.to allow_value(" $example.com/value ").for(:payment_pointer) }
      it { is_expected.to allow_value(nil).for(:payment_pointer) }
      it { is_expected.to allow_value("").for(:payment_pointer) }

      it { is_expected.to validate_length_of(:email).is_at_most(50).allow_nil }
      it { is_expected.to validate_length_of(:name).is_at_most(100).is_at_least(1) }
      it { is_expected.to validate_length_of(:password).is_at_most(100).is_at_least(8) }
      it { is_expected.to validate_length_of(:username).is_at_most(30).is_at_least(2) }

      it { is_expected.not_to allow_value("  ").for(:name) }

      it { is_expected.to validate_presence_of(:articles_count) }
      it { is_expected.to validate_presence_of(:badge_achievements_count) }
      it { is_expected.to validate_presence_of(:blocked_by_count) }
      it { is_expected.to validate_presence_of(:blocking_others_count) }
      it { is_expected.to validate_presence_of(:comments_count) }
      it { is_expected.to validate_presence_of(:credits_count) }
      it { is_expected.to validate_presence_of(:following_orgs_count) }
      it { is_expected.to validate_presence_of(:following_tags_count) }
      it { is_expected.to validate_presence_of(:following_users_count) }
      it { is_expected.to validate_presence_of(:rating_votes_count) }
      it { is_expected.to validate_presence_of(:reactions_count) }
      it { is_expected.to validate_presence_of(:sign_in_count) }
      it { is_expected.to validate_presence_of(:spent_credits_count) }
      it { is_expected.to validate_presence_of(:subscribed_to_user_subscriptions_count) }

      # rubocop:disable RSpec/NestedGroups
      context "when evaluating the custom error message for username uniqueness" do
        subject { create(:user, username: "test_user_123") }

        it { is_expected.to validate_uniqueness_of(:username).with_message("has already been taken").case_insensitive }
      end
      # rubocop:enable RSpec/NestedGroups

      Authentication::Providers.username_fields.each do |username_field|
        it { is_expected.to validate_uniqueness_of(username_field).allow_nil }
      end
    end

    it "renders custom error message with value of taken username" do
      create(:user, username: "test_user_123")
      same_username = build(:user, username: "test_user_123")
      expect(same_username).not_to be_valid
      expect(same_username.errors[:username].to_s).to include("has already been taken")
    end

    it "validates username against reserved words" do
      user = build(:user, username: "readinglist")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s).to include("reserved")
    end

    it "takes organization slug into account" do
      create(:organization, slug: "lightalloy")
      user = build(:user, username: "lightalloy")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s).to include("taken")
    end

    it "takes podcast slug into account" do
      create(:podcast, slug: "lightpodcast")
      user = build(:user, username: "lightpodcast")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s).to include("taken")
    end

    it "takes page slug into account" do
      create(:page, slug: "page_yo")
      user = build(:user, username: "page_yo")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s).to include("taken")
    end

    it "validates can_send_confirmation_email for existing user" do
      user = create(:user)
      limiter = RateLimitChecker.new(user)
      allow(user).to receive(:rate_limiter).and_return(limiter)
      allow(limiter).to receive(:limit_by_action).and_return(true)
      allow(limiter).to receive(:track_limit_by_action)
      user.update(email: "new_email@yo.com")

      expect(user).not_to be_valid
      expect(user.errors[:email].to_s).to include("confirmation could not be sent. Rate limit reached")
      expect(limiter).to have_received(:track_limit_by_action).with(:send_email_confirmation).twice
    end

    it "validates update_rate_limit for existing user" do
      user = create(:user)
      limiter = RateLimitChecker.new(user)
      allow(user).to receive(:rate_limiter).and_return(limiter)
      allow(limiter).to receive(:limit_by_action).and_return(true)
      allow(limiter).to receive(:track_limit_by_action)
      user.update(articles_count: 5)

      expect(user).not_to be_valid
      expect(user.errors[:base].to_s).to include("could not be saved. Rate limit reached")
      expect(limiter).to have_received(:track_limit_by_action).with(:user_update).twice
    end
  end

  context "when callbacks are triggered before validation" do
    let(:user) { build(:user) }

    Authentication::Providers.username_fields.each do |username_field|
      describe username_field do
        it "sets #{username_field} to nil if empty" do
          user.assign_attributes(username_field => "")
          user.validate!
          expect(user.attributes[username_field.to_s]).to be_nil
        end

        it "does not change a valid name" do
          user.assign_attributes(username_field => "hello")
          user.validate!
          expect(user.attributes[username_field.to_s]).to eq("hello")
        end
      end
    end

    describe "#email" do
      it "sets email to nil if empty" do
        user.email = ""
        user.validate!
        expect(user.email).to be_nil
      end

      it "does not change a valid name" do
        user.email = "anna@example.com"
        user.validate!
        expect(user.email).to eq("anna@example.com")
      end
    end

    describe "#username" do
      it "receives a generated username if none is given" do
        user.username = ""
        user.validate!
        expect(user.username).not_to be_blank
      end

      it "is not valid if generate_username returns nil" do
        user.username = ""
        allow(user).to receive(:generate_username).and_return(nil)
        expect(user).not_to be_valid
      end

      it "does not allow to change to a username that is taken" do
        user.username = other_user.username
        expect(user).not_to be_valid
      end

      it "does not allow to change to a username that is taken by an organization" do
        user.username = create(:organization).slug
        expect(user).not_to be_valid
      end
    end
  end

  context "when callbacks are triggered before and after create" do
    let(:user) { create(:user, email: nil) }

    describe "#send_welcome_notification" do
      let(:mascot_account) { create(:user) }
      let!(:set_up_profile_broadcast) { create(:set_up_profile_broadcast) }

      before do
        allow(described_class).to receive(:mascot_account).and_return(mascot_account)
      end

      it "sends a setup welcome notification when an active broadcast exists" do
        new_user = nil
        sidekiq_perform_enqueued_jobs do
          new_user = create(:user)
        end
        expect(new_user.reload.notifications.count).to eq(1)
        expect(new_user.reload.notifications.first.notifiable).to eq(set_up_profile_broadcast)
      end

      it "does not send a setup welcome notification without an active broadcast" do
        set_up_profile_broadcast.update!(active: false)
        new_user = nil
        sidekiq_perform_enqueued_jobs do
          new_user = create(:user)
        end
        expect(new_user.reload.notifications.count).to eq(0)
      end
    end

    it "refreshes user segments" do
      expect(user).to be_persisted
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
      user.update name: "New Name Here"
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(user.id)
    end
  end

  context "when callbacks are triggered after commit" do
    describe "subscribing to mailchimp newsletter" do
      let(:user) { build(:user) }

      it "enqueues SubscribeToMailchimpNewsletterWorker" do
        sidekiq_assert_enqueued_with(job: Users::SubscribeToMailchimpNewsletterWorker, args: user.id) do
          user.save
        end
      end

      it "does not enqueue without an email" do
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          user.update(email: "")
        end
      end

      it "does not enqueue with an unconfirmed email" do
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          user.update(unconfirmed_email: "bob@bob.com", confirmation_sent_at: Time.current)
        end
      end

      it "does not enqueue with a non-registered user" do
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          user.update(registered: false)
        end
      end

      it "does not enqueue if Mailchimp is not enabled" do
        allow(Settings::General).to receive(:mailchimp_api_key).and_return(nil)
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          user.update(email: "something@real.com")
        end
      end

      it "does not enqueue when the email address or subscription status has not changed" do
        # The trait replaces the method with a dummy, but we need the actual method for this test.
        user = described_class.find(create(:user, :ignore_mailchimp_subscribe_callback).id)

        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          user.update(credits_count: 100)
        end
      end
    end
  end

  context "when a new role is added" do
    let(:without_role) { create(:user, roles: []) }

    it "refreshes user segments" do
      without_role.add_role :trusted
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(without_role.id)
    end
  end

  describe "user registration", vcr: { cassette_name: "fastly_sloan" } do
    let(:user) { create(:user) }

    before do
      omniauth_mock_providers_payload
    end

    Authentication::Providers.available.each do |provider_name|
      it "finds user by email and assigns identity to that if exists for #{provider_name}" do
        OmniAuth.config.mock_auth[provider_name].info.email = user.email

        new_user = user_from_authorization_service(provider_name)
        expect(new_user.id).to eq(user.id)
      end

      it "assigns random username if username is taken on registration for #{provider_name}" do
        OmniAuth.config.mock_auth[provider_name].info.nickname = user.username
        OmniAuth.config.mock_auth[provider_name].info.first_name = user.username

        new_user = user_from_authorization_service(provider_name)

        expect(new_user.persisted?).to be(true)
        expect(new_user.username).not_to eq(user.username)
      end

      it "assigns signup_cta_variant to state param if new user for #{provider_name}" do
        new_user = user_from_authorization_service(provider_name, nil, "hey-hey-hey")
        expect(new_user.signup_cta_variant).to eq("hey-hey-hey")
      end

      it "does not assign signup_cta_variant to non-new users for #{provider_name}" do
        returning_user = create(:user, signup_cta_variant: nil)
        new_user = user_from_authorization_service(provider_name, returning_user, "hey-hey-hey")
        expect(new_user.signup_cta_variant).to be_nil
      end

      it "assigns proper social username based on authentication for #{provider_name}" do
        mock_username(provider_name, "valid_username")
        new_user = user_from_authorization_service(provider_name)

        case provider_name
        when :apple
          expect(new_user.username).to match(/valid_username_\w+/)
        when :facebook, :google_oauth2
          expect(new_user.username).to match(/fname_lname_\S*\z/)
        else
          expect(new_user.username).to eq("valid_username")
        end
      end

      it "marks registered_at for newly registered user" do
        new_user = user_from_authorization_service(provider_name, nil, "navbar_basic")
        expect(new_user.registered_at).not_to be_nil
      end

      it "assigns modified username if the username is invalid for #{provider_name}" do
        mock_username(provider_name, "invalid.username")
        new_user = user_from_authorization_service(provider_name)

        case provider_name
        when :apple
          expect(new_user.username).to match(/invalidusername_\w+/)
        when :facebook, :google_oauth2
          expect(new_user.username).to match(/fname_lname_\S*\z/)
        else
          expect(new_user.username).to eq("invalidusername")
        end
      end

      it "serializes the authentication payload for #{provider_name}" do
        new_user = user_from_authorization_service(provider_name)

        identity = new_user.identities.last
        expect(identity.auth_data_dump.provider).to eq(identity.provider)
      end

      it "does not allow previously banished users to sign up again for #{provider_name}" do
        banished_name = "SpammyMcSpamface"
        mock_username(provider_name, banished_name)

        create(:banished_user, username: provider_username(provider_name))
        expect do
          user_from_authorization_service(provider_name, nil, "navbar_basic")
        end.to raise_error(ActiveRecord::RecordInvalid, /Username has been banished./)
      end
    end

    it "assigns multiple identities to the same user", :aggregate_failures, vcr: { cassette_name: "fastly_sloan" } do
      providers = Authentication::Providers.available

      users = []
      Authentication::Providers.available.each do |provider_name|
        OmniAuth.config.mock_auth[provider_name].info.email = "person1@example.com"

        users.append(user_from_authorization_service(provider_name))
      end

      expect(users.uniq.first.identities.count).to eq(providers.length)
    end
  end

  it "does not allow an existing user to change their name to a banished one" do
    banished_name = "SpammyMcSpamface"
    create(:banished_user, username: banished_name)
    user = create(:user)

    user.update(username: banished_name)
    expect(user.errors.full_messages).to include("Username has been banished.")
  end

  describe "#follow and #all_follows" do
    it "follows users" do
      expect do
        user.follow(create(:user))
      end.to change(user.all_follows, :size).by(1)
    end
  end

  describe "spam" do
    it "delegates spam handling to Spam::Handler.handle_user!" do
      allow(Spam::Handler).to receive(:handle_user!).with(user: user).and_call_original

      user.save
    end
  end

  describe "#suspended?" do
    subject { user.suspended? }

    context "with suspended role" do
      before do
        user.add_role(:suspended)
      end

      it { is_expected.to be true }
    end

    it { is_expected.to be false }
  end

  describe "#comment_suspended?" do
    subject { user.comment_suspended? }

    context "with comment_suspended role" do
      before do
        user.add_role(:comment_suspended)
      end

      it { is_expected.to be true }
    end

    it { is_expected.to be false }
  end

  describe "#moderator_for_tags" do
    let(:tags) { create_list(:tag, 2) }

    it "lists tags user moderates" do
      user.add_role(:tag_moderator, tags.first)

      expect(user.moderator_for_tags).to include(tags.first.name)
      expect(user.moderator_for_tags).not_to include(tags.last.name)
    end

    it "returns empty array if no tags moderated" do
      expect(user.moderator_for_tags).to be_empty
    end
  end

  describe "#followed_articles" do
    let!(:another_user) { create(:user) }
    let!(:articles) { create_list(:article, 2, user: another_user) }

    before do
      user.follow(another_user)
    end

    it "returns all articles following" do
      expect(user.followed_articles.size).to eq(articles.size)
    end

    it "returns segment of articles if limit is passed" do
      expect(user.followed_articles.limit(1).size).to eq(articles.size - 1)
    end
  end

  describe "theming properties" do
    before do
      allow(Settings::UserExperience).to receive(:default_font).and_return("sans-serif")
    end

    it "creates proper body class with defaults" do
      # rubocop:disable Layout/LineLength
      classes = "light-theme sans-serif-article-body mod-status-#{user.admin? || !user.moderator_for_tags.empty?} trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header"
      # rubocop:enable Layout/LineLength
      expect(user.decorate.config_body_class).to eq(classes)
    end

    it "creates proper body class with sans serif config" do
      user.setting.config_font = "sans_serif"

      # rubocop:disable Layout/LineLength
      classes = "light-theme sans-serif-article-body mod-status-#{user.admin? || !user.moderator_for_tags.empty?} trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header"
      # rubocop:enable Layout/LineLength
      expect(user.decorate.config_body_class).to eq(classes)
    end

    it "creates proper body class with open dyslexic config" do
      user.setting.config_font = "open_dyslexic"

      # rubocop:disable Layout/LineLength
      classes = "light-theme open-dyslexic-article-body mod-status-#{user.admin? || !user.moderator_for_tags.empty?} trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header"
      # rubocop:enable Layout/LineLength
      expect(user.decorate.config_body_class).to eq(classes)
    end

    it "creates proper body class with dark theme" do
      user.setting.config_theme = "dark_theme"

      # rubocop:disable Layout/LineLength
      classes = "dark-theme sans-serif-article-body mod-status-#{user.admin? || !user.moderator_for_tags.empty?} trusted-status-#{user.trusted?} #{user.setting.config_navbar}-header ten-x-hacker-theme"
      # rubocop:enable Layout/LineLength
      expect(user.decorate.config_body_class).to eq(classes)
    end
  end

  describe "#set_initial_roles!" do
    it "adds creator roles if waiting on first user" do
      allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)

      user = create(:user)
      user.set_initial_roles!

      expect(user).to be_creator
      expect(user).to be_super_admin
      expect(user).to be_trusted
      expect(user).not_to be_limited
    end

    it "does not add any roles if not waiting on first user" do
      user = create(:user)
      user.set_initial_roles!

      expect(user).not_to be_creator
      expect(user).not_to be_super_admin
      expect(user).not_to be_trusted
      expect(user).not_to be_limited
    end

    it "adds the limited role to a new user if the new user status setting is limited" do
      allow(Settings::Authentication).to receive(:new_user_status).and_return("limited")

      user = create(:user)
      user.set_initial_roles!

      expect(user).not_to be_creator
      expect(user).not_to be_super_admin
      expect(user).not_to be_trusted
      expect(user).to be_limited
    end

    it "does not change any roles if the user is not a new user" do
      create(:user, :trusted, email: "trusted-user@forem.test")

      # Now considered an already existing record to ActiveRecord
      user = described_class.find_by(email: "trusted-user@forem.test")
      expect(UserRole.count).to eq(1)

      expect { user.set_initial_roles! }.not_to change(UserRole, :count)
      expect(user).to be_trusted
    end

    it "does not change any roles if the user is not valid" do
      user = create(:user, :tag_moderator)
      expect(UserRole.count).to eq(1)

      user.username = ""
      expect { user.set_initial_roles! }.not_to change(UserRole, :count)
      expect(user).to be_tag_moderator
    end

    it "does nothing if the user has not been persisted" do
      user = build(:user)
      expect(UserRole.count).to eq(0)

      expect { user.set_initial_roles! }.not_to change(UserRole, :count)
    end
  end

  describe "#calculate_score" do
    it "calculates a score" do
      user.update_column(:badge_achievements_count, 3)

      user.calculate_score
      expect(user.score).to eq(30)
    end
  end

  describe "cache counts" do
    it "has an accurate tag follow count" do
      tag = create(:tag)
      user.follow(tag)
      expect(user.reload.following_tags_count).to eq(1)
    end

    it "has an accurate user follow count" do
      user.follow(other_user)
      expect(user.reload.following_users_count).to eq(1)
    end

    it "has an accurate organization follow count" do
      user.follow(org)
      expect(user.reload.following_orgs_count).to eq(1)
    end

    it "returns cached ids of published articles that have been saved to their readinglist" do
      article = create(:article)
      article2 = create(:article)
      article3 = create(:article)

      create(:reading_reaction, user: user, reactable: article)
      create(:reading_reaction, user: user, reactable: article2)
      create(:reading_reaction, user: user, reactable: article3)

      Articles::Unpublish.call(article2.user, article2)

      expect(user.cached_reading_list_article_ids).to eq([article3.id, article.id])
    end
  end

  describe "#org_admin?" do
    it "recognizes an org admin" do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      expect(user.org_admin?(org)).to be(true)
    end

    it "forbids an incorrect org admin" do
      other_org = create(:organization)
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      expect(user.org_admin?(other_org)).to be(false)
      expect(other_user.org_admin?(org)).to be(false)
    end

    it "returns false if nil is given" do
      expect(user.org_admin?(nil)).to be(false)
    end
  end

  describe "#enough_credits?" do
    it "returns false if the user has less unspent credits than neeed" do
      expect(user.enough_credits?(1)).to be(false)
    end

    it "returns true if the user has the exact amount of unspent credits" do
      create(:credit, user: user, spent: false)
      expect(user.enough_credits?(1)).to be(true)
    end

    it "returns true if the user has more unspent credits than needed" do
      create_list(:credit, 2, user: user, spent: false)
      expect(user.enough_credits?(1)).to be(true)
    end
  end

  describe "#receives_follower_email_notifications?" do
    it "returns false if user has no email" do
      user.assign_attributes(email: nil)
      expect(user.receives_follower_email_notifications?).to be(false)
    end

    it "returns false if user opted out from follower notifications" do
      user.notification_setting.update(email_follower_notifications: false)
      expect(user.receives_follower_email_notifications?).to be(false)
    end

    it "returns true if user opted in from follower notifications and has an email" do
      user.notification_setting.update(email_follower_notifications: true)
      expect(user.receives_follower_email_notifications?).to be(true)
    end
  end

  describe ".staff_account" do
    it "returns nil if the account does not exist" do
      expect(described_class.staff_account).to be_nil
    end

    it "returns the user if the account exists" do
      allow(Settings::Community).to receive(:staff_user_id).and_return(user.id)

      expect(described_class.staff_account).to eq(user)
    end
  end

  describe ".mascot_account" do
    it "returns nil if the account does not exist" do
      expect(described_class.mascot_account).to be_nil
    end

    it "returns the user if the account exists" do
      allow(Settings::General).to receive(:mascot_user_id).and_return(user.id)

      expect(described_class.mascot_account).to eq(user)
    end
  end

  describe "#authenticated_through?" do
    let(:provider) { Authentication::Providers.available.first }

    it "returns false if provider is not known" do
      expect(user.authenticated_through?(:unknown)).to be(false)
    end

    it "returns false if provider is not enabled" do
      providers = Authentication::Providers.available - [provider]
      allow(Authentication::Providers).to receive(:enabled).and_return(providers)

      expect(user.authenticated_through?(provider)).to be(false)
    end

    it "returns false if the user has no related identity" do
      expect(user.authenticated_through?(provider)).to be(false)
    end

    it "returns true if the user has related identity" do
      user = create(:user, :with_identity, identities: [provider])
      expect(user.authenticated_through?(provider)).to be(true)
    end
  end

  describe "#authenticated_with_all_providers?" do
    let(:provider) { (Authentication::Providers.available - [:apple]).first }

    it "returns false if the user has no related identity" do
      expect(user.authenticated_with_all_providers?).to be(false)
    end

    it "returns false if the user is missing any of the identities" do
      providers = Authentication::Providers.available - [provider]
      user = create(:user, :with_identity, identities: providers)

      expect(user.authenticated_with_all_providers?).to be(false)
    end

    it "returns true if the user has all the enabled providers" do
      allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)

      user = create(:user, :with_identity)

      expect(user.authenticated_with_all_providers?).to be(true)
    end
  end

  describe "profiles" do
    it "automatically creates a profile for new users", :aggregate_failures do
      user = create(:user)
      expect(user.profile).to be_present
      expect(user.profile).to respond_to(:location)
    end
  end

  describe "#last_activity" do
    it "determines a user's last activity" do
      Timecop.freeze do
        user = create(:user, last_comment_at: 1.minute.ago)
        expect(user.last_activity).to eq(Time.zone.now)
      end
    end
  end

  describe ".recently_active" do
    let(:early) { build(:user) }
    let(:later) { build(:user) }

    before do
      later.save!

      Timecop.travel(5.days.ago) do
        early.save!
      end
    end

    it "returns the most recently updated" do
      results = described_class.recently_active(1)
      expect(results).to contain_exactly(later)
    end
  end

  describe "#currently_following_tags" do
    before do
      allow(Tag).to receive(:followed_by)
    end

    it "calls Tag.followed_by" do
      user.currently_following_tags
      expect(Tag).to have_received(:followed_by).with(user)
    end
  end

  describe "#has_no_published_content?" do
    it "returns true if the user has no published articles or comments" do
      create(:article, user_id: user.id, published: false, published_at: Date.tomorrow)
      expect(user.has_no_published_content?).to be(true)
    end

    it "returns false if the user has any published articles or comments" do
      create(:article, user_id: user.id, published: true)
      expect(user.has_no_published_content?).to be(false)
    end
  end

  describe ".above_average and .average_x_count" do
    context "when there are not yet any articles with score above 0" do
      it "works as expected" do
        expect(described_class.average_articles_count).to be_within(0.1).of(0.0)
        expect(described_class.average_comments_count).to be_within(0.1).of(0.0)
        users = described_class.above_average
        expect(users.pluck(:articles_count)).to eq([])
        expect(users.pluck(:comments_count)).to eq([])
      end
    end

    context "when there are users with articles_count" do
      before do
        create(:user, articles_count: 10)
        create(:user, articles_count: 6)
        create(:user, articles_count: 4)
        create(:user, articles_count: 1)
        # averages 5.25
      end

      it "works as expected" do
        expect(described_class.average_articles_count).to be_within(0.1).of(5.25)
        articles = described_class.above_average
        expect(articles.pluck(:articles_count)).to contain_exactly(10, 6)
      end
    end

    context "when there are users with comments_count" do
      before do
        create(:user, comments_count: 5)
        create(:user, comments_count: 4)
        create(:user, comments_count: 3)
        create(:user, comments_count: 2)
        # averages 3.5
      end

      it "works as expected" do
        expect(described_class.average_comments_count).to be_within(0.1).of(3.5)
        articles = described_class.above_average
        # average is decimal but gets floored by the query builder
        expect(articles.pluck(:comments_count)).to contain_exactly(5, 4, 3)
      end
    end
  end

  describe "#generate_social_images" do
    before do
      create(:article, user: user)
      allow(Images::SocialImageWorker).to receive(:perform_async)
    end

    context "when the name or profile_image has changed and the user has articles" do
      it "calls SocialImageWorker.perform_async" do
        user.name = "New name for this user!"
        user.save
        expect(Images::SocialImageWorker).to have_received(:perform_async)
      end
    end

    context "when the name or profile_image has not changed or the user has no articles" do
      it "does not call SocialImageWorker.perform_async" do
        user.save
        expect(Images::SocialImageWorker).not_to have_received(:perform_async)
      end
    end
  end
end
