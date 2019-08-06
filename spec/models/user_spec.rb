require "rails_helper"

RSpec.describe User, type: :model do
  let!(:user)           { create(:user) }
  let(:returning_user)  { create(:user, signup_cta_variant: nil) }
  let(:second_user)     { create(:user) }
  let(:article)         { create(:article, user_id: user.id) }
  let(:tag)             { create(:tag) }
  let(:org)             { create(:organization) }
  let(:second_org)      { create(:organization) }

  before { mock_auth_hash }

  describe "validations" do
    it { is_expected.to have_many(:api_secrets) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:badge_achievements).dependent(:destroy) }
    it { is_expected.to have_many(:badges).through(:badge_achievements) }
    it { is_expected.to have_many(:collections).dependent(:destroy) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:email_messages).class_name("Ahoy::Message") }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
    it { is_expected.to have_many(:mentions).dependent(:destroy) }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:tweets).dependent(:destroy) }
    it { is_expected.to have_many(:github_repos).dependent(:destroy) }
    it { is_expected.to have_many(:chat_channel_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:chat_channels).through(:chat_channel_memberships) }
    it { is_expected.to have_many(:push_notification_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:github_username).allow_nil }
    it { is_expected.to validate_uniqueness_of(:twitter_username).allow_nil }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_most(30).is_at_least(2) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_inclusion_of(:inbox_type).in_array(%w[open private]) }
    it { is_expected.to have_many(:access_grants).class_name("Doorkeeper::AccessGrant").with_foreign_key("resource_owner_id").dependent(:delete_all) }
    it { is_expected.to have_many(:access_tokens).class_name("Doorkeeper::AccessToken").with_foreign_key("resource_owner_id").dependent(:delete_all) }

    it "validates username against reserved words" do
      user = build(:user, username: "readinglist")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s.include?("reserved")).to be true
    end

    it "takes organization slug into account" do
      create(:organization, slug: "lightalloy")
      user = build(:user, username: "lightalloy")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s.include?("taken")).to be true
    end

    it "takes podcast slug into account" do
      create(:podcast, slug: "lightpodcast")
      user = build(:user, username: "lightpodcast")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s.include?("taken")).to be true
    end

    it "takes page slug into account" do
      create(:page, slug: "page_yo")
      user = build(:user, username: "page_yo")
      expect(user).not_to be_valid
      expect(user.errors[:username].to_s.include?("taken")).to be true
    end
  end

  # the followings are failing
  # it { is_expected.to have_many(:keys) }
  # it { is_expected.to have_many(:job_applications) }
  # it { is_expected.to have_many(:answers) }
  # it { is_expected.to validate_uniqueness_of(:email).case_insensitive.allow_blank }

  def user_from_authorization_service(service_name, signed_in_resource, cta_variant)
    auth = OmniAuth.config.mock_auth[service_name]
    service = AuthorizationService.new(auth, signed_in_resource, cta_variant)
    service.get_user
  end

  describe "makes sure usernames and email are not blank" do
    it "sets twitter username to nil" do
      user = create(:user, twitter_username: "")
      user.reload
      expect(user.twitter_username).to eq(nil)
    end

    it "sets github username to nil" do
      user = create(:user, github_username: "")
      user.reload
      expect(user.github_username).to eq(nil)
    end

    it "sets correct usernames if they are not blank" do
      user = create(:user, github_username: "hello", twitter_username: "world")
      user.reload
      expect(user.github_username).to eq("hello")
      expect(user.twitter_username).to eq("world")
    end

    it "sets email to nil" do
      user = create(:user, email: "")
      user.reload
      expect(user.email).to eq(nil)
    end

    it "sets correct email if it's not blank" do
      user = create(:user, email: "anna@example.com")
      user.reload
      expect(user.email).to eq("anna@example.com")
    end
  end

  describe "validations" do
    it "gets a username after create" do
      expect(user.username).not_to eq(nil)
    end

    it "does not accept invalid website url" do
      user.website_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https mastodon url" do
      user.mastodon_url = "https://mastodon.social/@test"
      expect(user).to be_valid
    end

    it "does not accept a denied mastodon instance" do
      user.mastodon_url = "https://SpammyMcSpamface.com/"
      expect(user).not_to be_valid
    end

    it "does not accept invalid mastodon url" do
      user.mastodon_url = "mastodon.social/@test"
      expect(user).not_to be_valid
    end

    it "accepts valid http website url" do
      user.website_url = "http://ben.com"
      expect(user).to be_valid
    end

    it "accepts valid https website url" do
      user.website_url = "https://ben.com"
      expect(user).to be_valid
    end

    it "accepts valid https facebook url" do
      %w[thepracticaldev thepracticaldev/ the.practical.dev].each do |username|
        user.facebook_url = "https://facebook.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid facebook url" do
      user.facebook_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https behance url" do
      %w[jess jess/ je-ss jes_ss].each do |username|
        user.behance_url = "https://behance.net/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid behance url" do
      user.behance_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "does not accept invalid twitch url" do
      user.twitch_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https twitch url" do
      %w[pandyzhao pandyzhao/ PandyZhao_ pandy_Zhao].each do |username|
        user.twitch_url = "https://twitch.tv/#{username}"
        expect(user).to be_valid
      end
    end

    it "accepts valid https stackoverflow url" do
      %w[pandyzhao pandyzhao/ pandy-zhao].each do |username|
        user.stackoverflow_url = "https://stackoverflow.com/users/7381391/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid stackoverflow url" do
      user.stackoverflow_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid stackoverflow sub community url" do
      %w[pt ru es ja].each do |subcommunity|
        user.stackoverflow_url = "https://#{subcommunity}.stackoverflow.com/users/7381391/mazen"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid stackoverflow sub community url" do
      user.stackoverflow_url = "https://fr.stackoverflow.com/users/7381391/mazen"
      expect(user).not_to be_valid
    end

    it "accepts valid https linkedin url" do
      %w[jessleenyc jessleenyc/ jess-lee-nyc].each do |username|
        user.linkedin_url = "https://linkedin.com/in/#{username}"
        expect(user).to be_valid
      end
    end

    it "accepts valid country specific https linkedin url" do
      user.linkedin_url = "https://mx.linkedin.com/in/jessleenyc"
      expect(user).to be_valid
    end

    it "does not accept three letters country codes in http linkedin url" do
      user.linkedin_url = "http://mex.linkedin.com/in/jessleenyc"
      expect(user).not_to be_valid
    end

    it "does not accept three letters country codes in https linkedin url" do
      user.linkedin_url = "https://mex.linkedin.com/in/jessleenyc"
      expect(user).not_to be_valid
    end

    it "does not accept invalid linkedin url" do
      user.linkedin_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https dribbble url" do
      %w[jess jess/ je-ss je_ss].each do |username|
        user.dribbble_url = "https://dribbble.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid dribbble url" do
      user.dribbble_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https medium url" do
      %w[jess jess/ je-ss je_ss].each do |username|
        user.medium_url = "https://medium.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid medium url" do
      user.medium_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "does not accept invalid instagram url" do
      user.instagram_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid instagram url" do
      %w[jess je_ss je_ss.tt A.z.E.r.T.y].each do |username|
        user.instagram_url = "https://instagram.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "accepts valid https gitlab url" do
      %w[jess jess/ je-ss je_ss].each do |username|
        user.gitlab_url = "https://gitlab.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid gitlab url" do
      user.gitlab_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "changes old_username and old_old_username properly if username changes" do
      old_username = user.username
      random_new_username = "username_#{rand(100_000_000)}"
      user.update(username: random_new_username)
      expect(user.username).to eq(random_new_username)
      expect(user.old_username).to eq(old_username)
      new_username = user.username
      user.update(username: "username_#{rand(100_000_000)}")
      expect(user.old_username).to eq(new_username)
      expect(user.old_old_username).to eq(old_username)
    end

    it "does not allow too short or too long name" do
      user.name = ""
      expect(user).not_to be_valid
      user.name = Faker::Lorem.paragraph_by_chars(200)
      expect(user).not_to be_valid
    end

    it "does not accept invalid employer url" do
      user.employer_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "does accept valid http employer url" do
      user.employer_url = "http://ben.com"
      expect(user).to be_valid
    end

    it "does accept valid https employer url" do
      user.employer_url = "https://ben.com"
      expect(user).to be_valid
    end

    it "enforces summary length validation if old summary was valid" do
      user.summary = "0" * 999
      user.save(validate: false)
      user.summary = "0" * 999
      expect(user).to be_valid
    end

    it "does not inforce summary validation if old summary was invalid" do
      user.summary = "0" * 999
      expect(user).not_to be_valid
    end

    it "accepts valid theme" do
      user.config_theme = "night theme"
      expect(user).to be_valid
    end

    it "does not accept invalid theme" do
      user.config_theme = "no night mode"
      expect(user).not_to be_valid
    end

    it "accepts valid font" do
      user.config_font = "sans serif"
      expect(user).to be_valid
    end

    it "does not accept invalid font" do
      user.config_theme = "goobledigook"
      expect(user).not_to be_valid
    end
  end

  ## Registration
  describe "user registration" do
    it "finds user by email and assigns identity to that if exists" do
      OmniAuth.config.mock_auth[:twitter].info.email = user.email

      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.id).to eq(user.id)
    end

    it "assigns random username if username is taken on registration" do
      OmniAuth.config.mock_auth[:twitter].info.nickname = user.username
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")

      expect(new_user.persisted?).to eq(true)
      expect(new_user.username).not_to eq(user.username)
    end

    it "assigns random username if username is taken by organization on registration" do
      org = create(:organization)
      OmniAuth.config.mock_auth[:twitter].info.nickname = org.slug

      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.persisted?).to eq(true)
      expect(new_user.username).not_to eq(org.slug)
    end

    it "assigns signup_cta_variant to state param with Twitter if new user" do
      new_user = user_from_authorization_service(:twitter, nil, "hey-hey-hey")
      expect(new_user.signup_cta_variant).to eq("hey-hey-hey")
    end

    it "does not assign signup_cta_variant to non-new users" do
      new_user = user_from_authorization_service(:twitter, returning_user, "hey-hey-hey")
      expect(new_user.signup_cta_variant).to eq(nil)
    end

    it "assigns proper social_username based on auth" do
      OmniAuth.config.mock_auth[:twitter].info.nickname = "valid_username"
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.username).to eq("valid_username")
    end

    it "assigns modified username if invalid" do
      OmniAuth.config.mock_auth[:twitter].info.nickname = "invalid.username"
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.username).to eq("invalidusername")
    end

    it "assigns an identity to user" do
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.identities.size).to eq(1)
      new_user = user_from_authorization_service(:github, nil, "navbar_basic")
      expect(new_user.identities.size).to eq(2)
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      expect(new_user.identities.size).to eq(2)
      new_user = user_from_authorization_service(:github, nil, "navbar_basic")
      expect(new_user.identities.size).to eq(2)
    end

    context "when estimating the default language" do
      it "sets correct language_settings by default" do
        user2 = create(:user, email: nil)
        expect(user2.language_settings).to eq("preferred_languages" => %w[en])
      end

      it "sets correct language_settings by default after the callbacks" do
        perform_enqueued_jobs do
          user2 = create(:user, email: nil)
          expect(user2.language_settings).to eq("preferred_languages" => %w[en])
        end
      end

      it "estimates default language to be nil" do
        perform_enqueued_jobs do
          user.estimate_default_language!
        end
        expect(user.reload.estimated_default_language).to eq(nil)
      end

      it "estimates default language to be japan with jp email" do
        perform_enqueued_jobs do
          user.update_column(:email, "ben@hello.jp")
          user.estimate_default_language!
        end
        expect(user.reload.estimated_default_language).to eq("ja")
      end

      it "estimates default language based on ID dump" do
        perform_enqueued_jobs do
          new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
          new_user.estimate_default_language!
          expect(user.reload.estimated_default_language).to eq(nil)
        end
      end

      it "returns proper preferred_languages_array" do
        perform_enqueued_jobs do
          user.update_column(:email, "ben@hello.jp")
          user.estimate_default_language!
        end
        expect(user.reload.preferred_languages_array).to include("ja")
      end
    end
  end

  describe "#preferred_languages_array" do
    it "returns a correct array when language settings are in a new format" do
      user.update_columns(language_settings: { estimated_default_language: "en", preferred_languages: %w[en ru it] })
      expect(user.preferred_languages_array).to eq(%w[en ru it])
    end

    it "returns a correct array when language settings are in the old format" do
      user.update_columns(language_settings: { estimated_default_language: "en", prefer_language_en: true, prefer_language_ja: false, prefer_language_es: true })
      expect(user.preferred_languages_array).to eq(%w[en es])
    end
  end

  it "follows users" do
    user2 = create(:user)
    user3 = create(:user)
    user.follow(user2)
    user.follow(user3)
    expect(user.all_follows.size).to eq(2)
  end

  describe "#followed_articles" do
    let(:user2)  { create(:user) }
    let(:user3)  { create(:user) }

    before do
      create_list(:article, 3, user_id: user2.id)
      user.follow(user2)
    end

    it "returns all articles following" do
      expect(user.followed_articles.size).to eq(3)
    end

    it "returns segment of articles if limit is passed" do
      expect(user.followed_articles.limit(2).size).to eq(2)
    end
  end

  describe "#cached_followed_tags" do
    let(:tag1)  { create(:tag) }
    let(:tag2)  { create(:tag) }
    let(:tag3)  { create(:tag) }
    let(:tag4)  { create(:tag) }

    it "returns empty if no tags followed" do
      expect(user.decorate.cached_followed_tags.size).to eq(0)
    end

    it "returns array of tags if user follows them" do
      user.follow(tag1)
      user.follow(tag2)
      user.follow(tag3)
      expect(user.decorate.cached_followed_tags.size).to eq(3)
    end

    it "returns tag object with name" do
      user.follow(tag1)
      expect(user.decorate.cached_followed_tags.first.name).to eq(tag1.name)
    end

    it "returns follow points for tag" do
      user.follow(tag1)
      expect(user.decorate.cached_followed_tags.first.points).to eq(1.0)
    end

    it "returns adjusted points for tag" do
      user.follow(tag1)
      Follow.last.update(points: 0.1)
      expect(user.decorate.cached_followed_tags.first.points).to eq(0.1)
    end
  end

  it "creates proper body class with defaults" do
    expect(user.decorate.config_body_class).to eq("default default-article-body pro-status-#{user.pro?}")
  end

  it "creates proper body class with sans serif config" do
    user.config_font = "sans_serif"
    expect(user.decorate.config_body_class).to eq("default sans-serif-article-body pro-status-#{user.pro?}")
  end

  it "creates proper body class with night theme" do
    user.config_theme = "night_theme"
    expect(user.decorate.config_body_class).to eq("night-theme default-article-body pro-status-#{user.pro?}")
  end

  it "creates proper body class with pink theme" do
    user.config_theme = "pink_theme"
    expect(user.decorate.config_body_class).to eq("pink-theme default-article-body pro-status-#{user.pro?}")
  end

  it "creates proper body class with minimal light theme" do
    user.config_theme = "minimal_light_theme"
    expect(user.decorate.config_body_class).to eq("minimal-light-theme default-article-body pro-status-#{user.pro?}")
  end

  it "creates proper body class with pro user" do
    user.add_role(:pro)
    expect(user.decorate.config_body_class).to eq("default default-article-body pro-status-#{user.pro?}")
  end

  it "inserts into mailchimp" do
    expect(user.subscribe_to_mailchimp_newsletter_without_delay).to eq true
  end

  it "does not allow to change to username that is taken" do
    user.username = second_user.username
    expect(user).not_to be_valid
  end

  it "does not allow to change to username that is taken by an organization" do
    user.username = create(:organization).slug
    expect(user).not_to be_valid
  end

  it "indexes into Algolia search" do
    user.index!
  end

  it "calculates score" do
    article.featured = true
    article.save
    user.calculate_score
    expect(user.score).to be > 0
  end

  it "persists JSON dump of identity data" do
    new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
    identity = new_user.identities.first
    expect(identity.auth_data_dump.provider).to eq(identity.provider)
  end

  it "persists extracts relevant identity data from logged in user" do
    new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
    expect(new_user.twitter_following_count).to be_an(Integer)
    expect(new_user.twitter_followers_count).to eq(100)
    expect(new_user.twitter_created_at).to be_kind_of(ActiveSupport::TimeWithZone)
    new_user = user_from_authorization_service(:github, nil, "navbar_basic")
    expect(new_user.github_created_at).to be_kind_of(ActiveSupport::TimeWithZone)
  end

  describe "cache counts" do
    it "has an accurate tag follow count" do
      user.follow(tag)
      expect(user.reload.following_tags_count).to eq 1
    end

    it "has an accurate user follow count" do
      user.follow(second_user)
      expect(user.reload.following_users_count).to eq 1
    end

    it "has an accurate organization follow count" do
      user.follow(org)
      expect(user.reload.following_orgs_count).to eq 1
    end
  end

  describe "organization admin privileges" do
    it "recognizes an org admin" do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      expect(user.org_admin?(org)).to be true
    end

    it "forbids an incorrect org admin" do
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      expect(user.org_admin?(second_org)).to be false
      expect(second_user.org_admin?(org)).to be false
    end

    it "responds to nil" do
      expect(user.org_admin?(nil)).to be false
      expect(second_user.org_admin?(nil)).to be false
    end
  end

  describe "#destroy" do
    it "successfully destroys a user" do
      user.destroy
      expect(user.persisted?).to be false
    end

    it "destroys associated organization memberships" do
      organization_membership = create(:organization_membership, user_id: user.id, organization_id: org.id)
      user.destroy
      expect { organization_membership.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "#pro?" do
    it "returns false if the user is not a pro" do
      expect(user.pro?).to be(false)
    end

    it "returns true if the user is a pro" do
      user.add_role(:pro)
      expect(user.pro?).to be(true)
    end
  end

  describe "when agolia auto-indexing/removal is triggered" do
    it "process background auto-indexing when user is saved" do
      expect { user.save }.to have_enqueued_job.with(user, "index!").on_queue("algoliasearch")
    end

    it "doesn't schedule a job on destroy" do
      expect { user.destroy }.not_to have_enqueued_job.on_queue("algoliasearch")
    end
  end
end
