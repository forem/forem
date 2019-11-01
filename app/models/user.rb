class User < ApplicationRecord
  include CloudinaryHelper

  attr_accessor(
    :scholar_email, :new_note, :note_for_current_role, :user_status, :pro, :merge_user_id,
    :add_credits, :remove_credits, :add_org_credits, :remove_org_credits, :ghostify
  )

  rolify
  include AlgoliaSearch
  include Storext.model

  acts_as_followable
  acts_as_follower

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :api_secrets, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :badge_achievements, dependent: :destroy
  has_many :badges, through: :badge_achievements
  has_many :collections, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :email_messages, class_name: "Ahoy::Message"
  has_many :github_repos, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes, as: :noteable, inverse_of: :noteable
  has_many :profile_pins, as: :profile, inverse_of: :profile
  has_many :authored_notes, as: :author, inverse_of: :author, class_name: "Note"
  has_many :notifications, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :tweets, dependent: :destroy
  has_many :chat_channel_memberships, dependent: :destroy
  has_many :chat_channels, through: :chat_channel_memberships
  has_many :notification_subscriptions, dependent: :destroy
  has_many :push_notification_subscriptions, dependent: :destroy
  has_many :feedback_messages
  has_many :rating_votes
  has_many :html_variants, dependent: :destroy
  has_many :page_views
  has_many :credits
  has_many :classified_listings
  has_many :poll_votes
  has_many :poll_skips
  has_many :backup_data, foreign_key: "instance_user_id", inverse_of: :instance_user, class_name: "BackupData"
  has_many :display_ad_events
  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", foreign_key: :resource_owner_id, inverse_of: :resource_owner, dependent: :delete_all
  has_many :access_tokens, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id, inverse_of: :resource_owner, dependent: :delete_all
  has_many :webhook_endpoints, class_name: "Webhook::Endpoint", foreign_key: :user_id, inverse_of: :user, dependent: :delete_all
  has_many :user_blocks
  has_one :pro_membership, dependent: :destroy

  mount_uploader :profile_image, ProfileImageUploader

  devise :omniauthable, :rememberable,
         :registerable, :database_authenticatable, :confirmable
  validates :email,
            length: { maximum: 50 },
            email: true,
            allow_nil: true
  validates :email, uniqueness: { allow_nil: true, case_sensitive: false }, if: :email_changed?
  validates :name, length: { minimum: 1, maximum: 100 }
  validates :username,
            presence: true,
            format: { with: /\A[a-zA-Z0-9_]+\Z/ },
            length: { in: 2..30 },
            exclusion: { in: ReservedWords.all, message: "username is reserved" }
  validates :username, uniqueness: { case_sensitive: false }, if: :username_changed?
  validates :twitter_username, uniqueness: { allow_nil: true }, if: :twitter_username_changed?
  validates :github_username, uniqueness: { allow_nil: true }, if: :github_username_changed?
  validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
  validates :text_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true
  validates :bg_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true
  validates :website_url, :employer_url, :mastodon_url,
            url: { allow_blank: true, no_local: true, schemes: %w[https http] }
  validates :facebook_url,
            format: /\A(http(s)?:\/\/)?(www.facebook.com|facebook.com)\/.*\Z/,
            allow_blank: true
  validates :stackoverflow_url,
            allow_blank: true,
            format:
            /\A(http(s)?:\/\/)?(((www|pt|ru|es|ja).)?stackoverflow.com|(www.)?stackexchange.com)\/.*\Z/
  validates :behance_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(www.behance.net|behance.net)\/.*\Z/
  validates :linkedin_url,
            allow_blank: true,
            format:
              /\A(http(s)?:\/\/)?(www.linkedin.com|linkedin.com|[A-Za-z]{2}.linkedin.com)\/.*\Z/
  validates :dribbble_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(www.dribbble.com|dribbble.com)\/.*\Z/
  validates :medium_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(www.medium.com|medium.com)\/.*\Z/
  validates :gitlab_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(www.gitlab.com|gitlab.com)\/.*\Z/
  validates :instagram_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(?:www.)?instagram.com\/(?=.{1,30}\/?$)([a-zA-Z\d_]\.?)*[a-zA-Z\d_]+\/?\Z/
  validates :twitch_url,
            allow_blank: true,
            format: /\A(http(s)?:\/\/)?(www.twitch.tv|twitch.tv)\/.*\Z/
  validates :shirt_gender,
            inclusion: { in: %w[unisex womens],
                         message: "%<value>s is not a valid shirt style" },
            allow_blank: true
  validates :shirt_size,
            inclusion: { in: %w[xs s m l xl 2xl 3xl 4xl],
                         message: "%<value>s is not a valid size" },
            allow_blank: true
  validates :tabs_or_spaces,
            inclusion: { in: %w[tabs spaces],
                         message: "%<value>s is not a valid answer" },
            allow_blank: true
  validates :editor_version,
            inclusion: { in: %w[v1 v2],
                         message: "%<value>s must be either v1 or v2" }

  validates :config_theme,
            inclusion: { in: %w[default night_theme pink_theme minimal_light_theme ten_x_hacker_theme],
                         message: "%<value>s is not a valid theme" }
  validates :config_font,
            inclusion: { in: %w[default sans_serif monospace comic_sans],
                         message: "%<value>s is not a valid font selection" }
  validates :config_navbar,
            inclusion: { in: %w[default static],
                         message: "%<value>s is not a valid navbar value" }
  validates :shipping_country,
            length: { in: 2..2 },
            allow_blank: true
  validates :website_url, :employer_name, :employer_url,
            length: { maximum: 100 }
  validates :employment_title, :education, :location,
            length: { maximum: 100 }
  validates :mostly_work_with, :currently_learning,
            :currently_hacking_on, :available_for,
            length: { maximum: 500 }
  validates :inbox_type, inclusion: { in: %w[open private] }
  validates :currently_streaming_on, inclusion: { in: %w[twitch] }, allow_nil: true
  validates :feed_referential_link, inclusion: [true, false]
  validate  :conditionally_validate_summary
  validate  :validate_mastodon_url
  validate  :validate_feed_url, if: :feed_url_changed?
  validate  :unique_including_orgs_and_podcasts, if: :username_changed?

  scope :dev_account, -> { find_by(id: ApplicationConfig["DEVTO_USER_ID"]) }

  after_create :send_welcome_notification
  after_save  :bust_cache
  after_save  :subscribe_to_mailchimp_newsletter
  after_save  :conditionally_resave_articles
  after_create :estimate_default_language
  before_create :set_default_language
  before_validation :set_username
  # make sure usernames are not empty, to be able to use the database unique index
  before_validation :verify_twitter_username, :verify_github_username, :verify_email, :verify_twitch_username
  before_validation :set_config_input
  before_validation :downcase_email
  before_validation :check_for_username_change
  before_destroy :remove_from_algolia_index, prepend: true
  before_destroy :destroy_empty_dm_channels, prepend: true
  before_destroy :destroy_follows, prepend: true
  before_destroy :unsubscribe_from_newsletters, prepend: true

  algoliasearch per_environment: true, enqueue: :trigger_delayed_index do
    attribute :name
    add_index "searchables",
              id: :index_id,
              per_environment: true,
              enqueue: true do
      attribute :user do
        {
          username: user.username,
          name: user.username,
          profile_image_90: profile_image_90,
          pro: user.pro?
        }
      end
      attribute :title, :path, :tag_list, :main_image, :id,
                :featured, :published, :published_at, :featured_number, :comments_count,
                :reactions_count, :positive_reactions_count, :class_name, :user_name,
                :user_username, :comments_blob, :body_text, :tag_keywords_for_search,
                :search_score, :hotness_score
      searchableAttributes ["unordered(title)",
                            "body_text",
                            "tag_list",
                            "tag_keywords_for_search",
                            "user_name",
                            "user_username",
                            "comments_blob"]
      attributesForFaceting [:class_name]
      customRanking ["desc(search_score)", "desc(hotness_score)"]
    end
  end

  def estimated_default_language
    language_settings["estimated_default_language"]
  end

  def self.trigger_delayed_index(record, remove)
    return if remove

    AlgoliaSearch::AlgoliaJob.perform_later(record, "index!")
  end

  def tag_line
    summary
  end

  def index_id
    "users-#{id}"
  end

  def set_remember_fields
    self.remember_token ||= self.class.remember_token if respond_to?(:remember_token)
    self.remember_created_at ||= Time.now.utc
  end

  def estimate_default_language
    Users::EstimateDefaultLanguageJob.perform_later(id)
  end

  def calculate_score
    score = (articles.where(featured: true).size * 100) + comments.sum(:score)
    update_column(:score, score)
  end

  def path
    "/" + username.to_s
  end

  def followed_articles
    Article.tagged_with(cached_followed_tag_names, any: true).
      union(Article.where(user_id: cached_following_users_ids)).
      where(language: preferred_languages_array, published: true)
  end

  def cached_following_users_ids
    Rails.cache.fetch(
      "user-#{id}-#{updated_at}-#{following_users_count}/following_users_ids",
      expires_in: 120.hours,
    ) do
      Follow.where(follower_id: id, followable_type: "User").limit(150).pluck(:followable_id)
    end
  end

  def cached_following_organizations_ids
    RedisRailsCache.fetch(
      "user-#{id}-#{updated_at}-#{following_orgs_count}/following_organizations_ids",
      expires_in: 120.hours,
    ) do
      Follow.where(follower_id: id, followable_type: "Organization").limit(150).pluck(:followable_id)
    end
  end

  def cached_following_podcasts_ids
    RedisRailsCache.fetch(
      "user-#{id}-#{updated_at}-#{last_followed_at}/following_podcasts_ids",
      expires_in: 120.hours,
    ) do
      Follow.where(follower_id: id, followable_type: "Podcast").pluck(:followable_id)
    end
  end

  # handles both old (prefer_language_*) and new (Array of language codes) formats
  def preferred_languages_array
    # return @prefer_languages_array if defined? @preferred_languages_array
    return @preferred_languages_array if defined?(@preferred_languages_array)

    if language_settings["preferred_languages"].present?
      @preferred_languages_array = language_settings["preferred_languages"].to_a
    else
      languages = []
      language_settings.each_key do |setting|
        languages << setting.split("prefer_language_")[1] if language_settings[setting] && setting.include?("prefer_language_")
      end
      @preferred_languages_array = languages
    end
    @preferred_languages_array
  end

  def processed_website_url
    website_url.to_s.strip if website_url.present?
  end

  def remember_me
    true
  end

  def cached_followed_tag_names
    cache_name = "user-#{id}-#{updated_at}/followed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.where(
        id: Follow.where(
          follower_id: id,
          followable_type: "ActsAsTaggableOn::Tag",
        ).pluck(:followable_id),
      ).pluck(:name)
    end
  end

  # methods for Administrate field
  def banned
    has_role? :banned
  end

  def warned
    has_role? :warned
  end

  def admin?
    has_role?(:super_admin)
  end

  def any_admin?
    has_role?(:super_admin) || has_role?(:admin)
  end

  def tech_admin?
    has_role?(:tech_admin) || has_role?(:super_admin)
  end

  def pro?
    Rails.cache.fetch("user-#{id}/has_pro_membership", expires_in: 200.hours) do
      pro_membership&.active? || has_role?(:pro)
    end
  end

  def trusted
    RedisRailsCache.fetch("user-#{id}/has_trusted_role", expires_in: 200.hours) do
      has_role? :trusted
    end
  end

  def moderator_for_tags
    Rails.cache.fetch("user-#{id}/tag_moderators_list", expires_in: 200.hours) do
      tag_ids = roles.where(name: "tag_moderator").pluck(:resource_id)
      Tag.where(id: tag_ids).pluck(:name)
    end
  end

  def scholar
    valid_pass = workshop_expiration.nil? || workshop_expiration > Time.current
    has_role?(:workshop_pass) && valid_pass
  end

  def comment_banned
    has_role? :comment_banned
  end

  def workshop_eligible?
    has_any_role?(:workshop_pass)
  end

  def admin_organizations
    org_ids = organization_memberships.where(type_of_user: "admin").pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def member_organizations
    org_ids = organization_memberships.where(type_of_user: %w[admin member]).pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def org_member?(organization)
    OrganizationMembership.exists?(user: user, organization: organization, type_of_user: %w[admin member])
  end

  def org_admin?(organization)
    OrganizationMembership.exists?(user: user, organization: organization, type_of_user: "admin")
  end

  def block; end

  def all_blocking
    UserBlock.where(blocker_id: id)
  end

  def all_blocked_by
    UserBlock.where(blocked_id: id)
  end

  def blocking?(blocked_id)
    UserBlock.blocking?(id, blocked_id)
  end

  def blocked_by?(blocker_id)
    UserBlock.blocking?(blocker_id, id)
  end

  def unique_including_orgs_and_podcasts
    errors.add(:username, "is taken.") if Organization.find_by(slug: username) || Podcast.find_by(slug: username) || Page.find_by(slug: username)
  end

  def subscribe_to_mailchimp_newsletter
    return unless email.present? && email.include?("@")
    return if saved_changes["unconfirmed_email"] && saved_changes["confirmation_sent_at"]

    Users::SubscribeToMailchimpNewsletterJob.perform_later(id)
  end

  def a_sustaining_member?
    monthly_dues.positive?
  end

  def resave_articles
    cache_buster = CacheBuster.new
    articles.find_each do |article|
      if article.path
        cache_buster.bust(article.path)
        cache_buster.bust(article.path + "?i=i")
      end
      article.save
    end
  end

  def settings_tab_list
    %w[
      Profile
      Integrations
      Notifications
      Publishing\ from\ RSS
      Organization
      Billing
      Account
      Misc
    ]
  end

  def profile_image_90
    ProfileImage.new(self).get(90)
  end

  def remove_from_algolia_index
    remove_from_index!
    Search::RemoveFromIndexJob.perform_later("searchables_#{Rails.env}", index_id)
  end

  def unsubscribe_from_newsletters
    MailchimpBot.new(self).unsubscribe_all_newsletters
  end

  def tag_moderator?
    roles.where(name: "tag_moderator").any?
  end

  def currently_streaming?
    currently_streaming_on.present?
  end

  def currently_streaming_on_twitch?
    currently_streaming_on == "twitch"
  end

  def has_enough_credits?(num_credits_needed)
    credits.unspent.size >= num_credits_needed
  end

  private

  def set_default_language
    language_settings["preferred_languages"] ||= ["en"]
  end

  def send_welcome_notification
    Notification.send_welcome_notification(id)
  end

  def verify_twitter_username
    self.twitter_username = nil if twitter_username == ""
  end

  def verify_github_username
    self.github_username = nil if github_username == ""
  end

  def verify_email
    self.email = nil if email == ""
  end

  def verify_twitch_username
    self.twitch_username = nil if twitch_username == ""
  end

  def set_username
    set_temp_username if username.blank?
    self.username = username&.downcase
  end

  def set_temp_username
    self.username = if temp_name_exists?
                      temp_username + "_" + rand(100).to_s
                    else
                      temp_username
                    end
  end

  def temp_name_exists?
    User.find_by(username: temp_username) || Organization.find_by(slug: temp_username)
  end

  def temp_username
    if twitter_username
      twitter_username.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ")
    elsif github_username
      github_username.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ")
    end
  end

  def downcase_email
    self.email = email.downcase if email
  end

  def set_config_input
    self.config_theme = config_theme.tr(" ", "_")
    self.config_font = config_font.tr(" ", "_")
    self.config_navbar = config_navbar.tr(" ", "_")
  end

  def check_for_username_change
    return unless username_changed?

    self.old_old_username = old_username
    self.old_username = username_was
    chat_channels.find_each do |channel|
      channel.slug = channel.slug.gsub(username_was, username)
      channel.save
    end
    articles.find_each do |article|
      article.path = article.path.gsub(username_was, username)
      article.save
    end
  end

  def conditionally_resave_articles
    Users::ResaveArticlesJob.perform_later(id) if core_profile_details_changed? && !user.banned
  end

  def bust_cache
    Users::BustCacheJob.perform_later(id)
  end

  def core_profile_details_changed?
    saved_change_to_username? ||
      saved_change_to_name? ||
      saved_change_to_summary? ||
      saved_change_to_bg_color_hex? ||
      saved_change_to_text_color_hex? ||
      saved_change_to_profile_image? ||
      saved_change_to_github_username? ||
      saved_change_to_twitter_username?
  end

  def conditionally_validate_summary
    # Grandfather people who had a too long summary before.
    return if summary_was && summary_was.size > 200

    errors.add(:summary, "is too long.") if summary.present? && summary.size > 200
  end

  def validate_feed_url
    return if feed_url.blank?

    errors.add(:feed_url, "is not a valid rss feed") unless RssReader.new.valid_feed_url?(feed_url)
  end

  def validate_mastodon_url
    return if mastodon_url.blank?

    uri = URI.parse(mastodon_url)
    return if uri.host&.in?(Constants::ALLOWED_MASTODON_INSTANCES)

    errors.add(:mastodon_url, "is not an allowed Mastodon instance")
  end

  def title
    name
  end

  def tag_list
    "" # Unused but necessary for search index
  end

  def main_image; end

  def featured
    true
  end

  def published
    true
  end

  def published_at; end

  def featured_number; end

  def positive_reactions_count
    reactions_count
  end

  def user
    self
  end

  def class_name
    self.class.name
  end

  def user_name
    username
  end

  def user_username
    username
  end

  def comments_blob
    "" # Unused but necessary for search index
  end

  def body_text
    "" # Unused but necessary for search index
  end

  def tag_keywords_for_search
    employer_name.to_s + mostly_work_with.to_s + available_for.to_s
  end

  def hotness_score
    search_score
  end

  def search_score
    counts_score = (articles_count + comments_count + reactions_count + badge_achievements_count) * 10
    score = (counts_score + tag_keywords_for_search.size) * reputation_modifier
    score.to_i
  end

  def destroy_empty_dm_channels
    return if chat_channels.empty? ||
      chat_channels.where(channel_type: "direct").empty?

    empty_dm_channels = chat_channels.where(channel_type: "direct").
      select { |chat_channel| chat_channel.messages.empty? }
    empty_dm_channels.destroy_all
  end

  def destroy_follows
    follower_relationships = Follow.where(followable_id: id, followable_type: "User")
    follower_relationships.destroy_all
    follows.destroy_all
  end
end
