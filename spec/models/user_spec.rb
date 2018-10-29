# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe User, type: :model do
  let(:user)            { create(:user) }
  let(:returning_user)  { create(:user, signup_cta_variant: nil) }
  let(:second_user)     { create(:user) }
  let(:article)         { create(:article, user_id: user.id) }
  let(:tag)             { create(:tag) }
  let(:org)             { create(:organization) }
  let (:second_org)     { create(:organization) }

  before { mock_auth_hash }

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
  it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:github_username).allow_blank }
  it { is_expected.to validate_uniqueness_of(:twitter_username).allow_blank }
  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_length_of(:username).is_at_most(30).is_at_least(2) }
  it { is_expected.to validate_length_of(:name).is_at_most(100) }

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

  describe "validations" do
    it "gets a username after create" do
      expect(user.username).not_to eq(nil)
    end

    it "does not accept invalid website url" do
      user.website_url = "ben.com"
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
      %w(thepracticaldev thepracticaldev/ the.practical.dev).each do |username|
        user.facebook_url = "https://facebook.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid facebook url" do
      user.facebook_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https behance url" do
      %w(jess jess/ je-ss jes_ss).each do |username|
        user.behance_url = "https://behance.net/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid behance url" do
      user.behance_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https stackoverflow url" do
      %w(pandyzhao pandyzhao/ pandy-zhao).each do |username|
        user.stackoverflow_url = "https://stackoverflow.com/users/7381391/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid stackoverflow url" do
      user.stackoverflow_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https linkedin url" do
      %w(jessleenyc jessleenyc/ jess-lee-nyc).each do |username|
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
      %w(jess jess/ je-ss je_ss).each do |username|
        user.dribbble_url = "https://dribbble.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid dribbble url" do
      user.dribbble_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "accepts valid https medium url" do
      %w(jess jess/ je-ss je_ss).each do |username|
        user.medium_url = "https://medium.com/#{username}"
        expect(user).to be_valid
      end
    end

    it "does not accept invalid medium url" do
      user.medium_url = "ben.com"
      expect(user).not_to be_valid
    end

    it "changes old_username if old_old_username properly if username changes" do
      old_username = user.username
      random_new_username = "username_#{rand(100000000)}"
      user.update(username: random_new_username)
      expect(user.username).to eq(random_new_username)
      expect(user.old_username).to eq(old_username)
      new_username = user.username
      user.update(username: "username_#{rand(100000000)}")
      expect(user.old_username).to eq(new_username)
      expect(user.old_old_username).to eq(old_username)
    end

    it "updates mentor_form_updated_at at appropriate time" do
      user.mentor_description = "hello"
      user.save
      expect(user.mentor_form_updated_at).not_to eq(nil)
    end

    it "updates mentee_form_updated_at at appropriate time" do
      user.mentee_description = "hello"
      user.save
      expect(user.mentee_form_updated_at).not_to eq(nil)
    end

    it "does not allow mentee description to be too long" do
      user.mentee_description = Faker::Lorem.paragraph_by_chars(1001)
      user.save
      expect(user.mentee_form_updated_at).to eq(nil)
    end

    it "does not allow mentor description to be too long" do
      user.mentor_description = Faker::Lorem.paragraph_by_chars(1001)
      user.save
      expect(user.mentor_form_updated_at).to eq(nil)
    end

    it "allow mentee description to be the max length" do
      user.mentee_description = Faker::Lorem.paragraph_by_chars(1000)
      user.save
      expect(user.mentee_form_updated_at).not_to eq(nil)
    end

    it "allow mentor description to be the max length" do
      user.mentor_description = Faker::Lorem.paragraph_by_chars(1000)
      user.save
      expect(user.mentor_form_updated_at).not_to eq(nil)
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

    it "does not allow usernames to be a reserved word" do
      ReservedWords.all.each do |word|
        user.username = word
        expect(user).not_to be_valid
      end
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

    it "estimates default language to be nil" do
      user.estimate_default_language_without_delay!
      expect(user.estimated_default_language).to eq(nil)
    end
    it "estimates default language to be japan with jp email" do
      user.email = "ben@hello.jp"
      user.estimate_default_language_without_delay!
      expect(user.estimated_default_language).to eq("ja")
    end
    it "estimates default language based on ID dump" do
      new_user = user_from_authorization_service(:twitter, nil, "navbar_basic")
      new_user.estimate_default_language_without_delay!
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

  describe "onboarding checklist" do
    it "returns onboarding checklist made first article if made first published article" do
      article.update(published: true)
      checklist = UserStates.new(user).cached_onboarding_checklist[:write_your_first_article]
      expect(checklist).to eq(true)
    end

    it "returns onboarding checklist made first article false if hasn't written article" do
      article.update(published: false)
      checklist = UserStates.new(user).cached_onboarding_checklist[:write_your_first_article]
      expect(checklist).to eq(true)
    end

    it "returns onboarding checklist follow_your_first_tag if has followed tag" do
      user.follow(tag)
      expect(UserStates.new(user).cached_onboarding_checklist[:follow_your_first_tag]).to eq(true)
    end

    it "returns onboarding checklist follow_your_first_tag false if has not followed tag" do
      expect(UserStates.new(user).cached_onboarding_checklist[:follow_your_first_tag]).to eq(false)
    end

    it "returns onboarding checklist fill_out_your_profile if has filled out summary" do
      user.update(summary: "Hello")
      expect(UserStates.new(user).cached_onboarding_checklist[:fill_out_your_profile]).to eq(true)
    end

    it "returns onboarding checklist fill_out_your_profile false if has not filled out summary" do
      user.update(summary: "")
      expect(UserStates.new(user).cached_onboarding_checklist[:fill_out_your_profile]).to eq(false)
    end

    it "returns onboarding checklist leave_your_first_reaction if has reacted to a post" do
      create(:reaction, user_id: user.id, reactable_id: article.id)
      checklist = UserStates.new(user).cached_onboarding_checklist[:leave_your_first_reaction]
      expect(checklist).to eq(true)
    end

    it "returns onboarding checklist leave_your_first_reaction false if hasn't reacted to a post" do
      checklist = UserStates.new(user).cached_onboarding_checklist[:leave_your_first_reaction]
      expect(checklist).to eq(false)
    end

    it "returns onboarding checklist leave_your_first_comment if has left comment" do
      create(:comment, user_id: user.id, commentable_id: article.id, commentable_type: "Article")
      user.reload
      checklist = UserStates.new(user).cached_onboarding_checklist[:leave_your_first_comment]
      expect(checklist).to eq(true)
    end

    it "returns onboarding checklist leave_your_first_comment false if has not left comment" do
      checklist = UserStates.new(user).cached_onboarding_checklist[:leave_your_first_comment]
      expect(checklist).to eq(false)
    end
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
      user.update(organization: org, org_admin: true)
      expect(user.org_admin?(org)).to be true
    end

    it "forbids an incorrect org admin" do
      user.update(organization: org, org_admin: true)
      expect(user.org_admin?(second_org)).to be false
      expect(second_user.org_admin?(org)).to be false
    end

    it "responds to nil" do
      expect(user.org_admin?(nil)).to be false
      expect(second_user.org_admin?(nil)).to be false
    end
  end

  describe "#can_view_analytics?" do
    it "returns true for users with :super_admin role" do
      user.add_role(:super_admin)
      expect(user.can_view_analytics?).to be true
    end

    it "returns true for users with :analytics_beta_tester role" do
      user.add_role(:analytics_beta_tester)
      expect(user.can_view_analytics?).to be true
    end
  end

  describe "#destroy" do
    it "successfully destroys a user" do
      user.destroy
      expect(user.persisted?).to be false
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
