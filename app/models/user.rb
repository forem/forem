class User < ApplicationRecord
  resourcify
  rolify after_add: :update_user_roles_cache, after_remove: :update_user_roles_cache

  include CloudinaryHelper

  include Images::Profile.for(:profile_image_url)
  include AlgoliaSearchable

  # NOTE: we are using an inline module to keep profile related things together.
  concerning :Profiles do
    included do
      has_one :profile, dependent: :delete

      # NOTE: There are rare cases were we want to skip this callback, primarily
      # in tests. `skip_callback` modifies global state, which is not thread-safe
      # and can cause hard to track down bugs. We use an instance-level attribute
      # instead. See `spec/factories/profiles.rb` for an example.
      attr_accessor :_skip_creating_profile

      # All new users should automatically have a profile
      after_create_commit -> { Profile.create(user: self) }, unless: :_skip_creating_profile
    end
  end

  include StringAttributeCleaner.nullify_blanks_for(:email)

  extend UniqueAcrossModels
  USERNAME_MAX_LENGTH = 30

  RECENTLY_ACTIVE_LIMIT = 10_000

  attr_accessor :scholar_email, :new_note, :note_for_current_role, :user_status, :merge_user_id,
                :add_credits, :remove_credits, :add_org_credits, :remove_org_credits, :ip_address,
                :current_password, :custom_invite_subject, :custom_invite_message, :custom_invite_footnote

  acts_as_followable
  acts_as_follower

  has_one :notification_setting, class_name: "Users::NotificationSetting", dependent: :delete
  has_one :setting, class_name: "Users::Setting", dependent: :delete

  has_many :affected_feedback_messages, class_name: "FeedbackMessage",
                                        inverse_of: :affected, foreign_key: :affected_id, dependent: :nullify
  has_many :ahoy_events, class_name: "Ahoy::Event", dependent: :delete_all
  has_many :ahoy_visits, class_name: "Ahoy::Visit", dependent: :delete_all
  has_many :api_secrets, dependent: :delete_all
  has_many :articles, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :authored_notes, inverse_of: :author, class_name: "Note", foreign_key: :author_id, dependent: :delete_all
  has_many :badge_achievements, dependent: :delete_all
  has_many :badge_achievements_rewarded, class_name: "BadgeAchievement", foreign_key: :rewarder_id,
                                         inverse_of: :rewarder, dependent: :nullify
  has_many :badges, through: :badge_achievements
  has_many :banished_users, class_name: "BanishedUser", foreign_key: :banished_by_id,
                            inverse_of: :banished_by, dependent: :nullify
  has_many :blocked_blocks, class_name: "UserBlock", foreign_key: :blocked_id,
                            inverse_of: :blocked, dependent: :delete_all
  has_many :blocker_blocks, class_name: "UserBlock", foreign_key: :blocker_id,
                            inverse_of: :blocker, dependent: :delete_all
  has_many :collections, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :created_podcasts, class_name: "Podcast", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
  has_many :credits, dependent: :destroy
  has_many :discussion_locks, dependent: :delete_all, inverse_of: :locking_user, foreign_key: :locking_user_id
  has_many :billboard_events, dependent: :nullify
  has_many :email_authorizations, dependent: :delete_all
  has_many :email_messages, class_name: "Ahoy::Message", dependent: :destroy
  has_many :feed_events, dependent: :nullify
  has_many :field_test_memberships, class_name: "FieldTest::Membership", as: :participant, dependent: :destroy
  # Consider that we might be able to use dependent: :delete_all as the GithubRepo busts the user cache
  has_many :github_repos, dependent: :destroy
  has_many :html_variants, dependent: :destroy
  has_many :identities, dependent: :delete_all
  has_many :identities_enabled, -> { enabled }, class_name: "Identity", inverse_of: false
  has_many :listings, dependent: :destroy
  has_many :mentions, dependent: :delete_all
  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :delete_all
  has_many :notification_subscriptions, dependent: :delete_all
  has_many :notifications, dependent: :delete_all
  has_many :offender_feedback_messages, class_name: "FeedbackMessage",
                                        inverse_of: :offender, foreign_key: :offender_id, dependent: :nullify
  has_many :organization_memberships, dependent: :delete_all
  has_many :organizations, through: :organization_memberships
  # we keep page views as they belong to the article, not to the user who viewed it
  has_many :page_views, dependent: :nullify
  has_many :podcast_episode_appearances, dependent: :delete_all, inverse_of: :user
  has_many :podcast_episodes, through: :podcast_episode_appearances, source: :podcast_episode
  has_many :podcast_ownerships, dependent: :delete_all, inverse_of: :owner
  has_many :podcasts_owned, through: :podcast_ownerships, source: :podcast
  has_many :poll_skips, dependent: :delete_all
  has_many :poll_votes, dependent: :delete_all
  has_many :profile_pins, as: :profile, inverse_of: :profile, dependent: :delete_all
  has_many :segmented_users, dependent: :destroy
  has_many :audience_segments, through: :segmented_users
  has_many :recommended_articles_lists, dependent: :destroy

  # we keep rating votes as they belong to the article, not to the user who viewed it
  has_many :rating_votes, dependent: :nullify

  has_many :reactions, dependent: :destroy
  has_many :reporter_feedback_messages, class_name: "FeedbackMessage",
                                        inverse_of: :reporter, foreign_key: :reporter_id, dependent: :nullify
  has_many :response_templates, inverse_of: :user, dependent: :delete_all
  has_many :source_authored_user_subscriptions, class_name: "UserSubscription",
                                                foreign_key: :author_id, inverse_of: :author, dependent: :destroy
  has_many :subscribed_to_user_subscriptions, class_name: "UserSubscription",
                                              foreign_key: :subscriber_id, inverse_of: :subscriber, dependent: :destroy
  has_many :subscribers, through: :source_authored_user_subscriptions, dependent: :destroy
  has_many :tweets, dependent: :nullify
  has_many :devices, dependent: :delete_all
  # languages that user undestands
  has_many :languages, class_name: "UserLanguage", inverse_of: :user, dependent: :delete_all
  has_many :user_visit_contexts, dependent: :delete_all

  mount_uploader :profile_image, ProfileImageUploader

  devise :invitable, :omniauthable, :registerable, :database_authenticatable, :confirmable, :rememberable,
         :recoverable, :lockable

  validates :articles_count, presence: true
  validates :badge_achievements_count, presence: true
  validates :blocked_by_count, presence: true
  validates :blocking_others_count, presence: true
  validates :comments_count, presence: true
  validates :credits_count, presence: true
  validates :email, length: { maximum: 50 }, email: true, allow_nil: true
  validates :email, uniqueness: { allow_nil: true, case_sensitive: false }, if: :email_changed?
  validates :following_orgs_count, presence: true
  validates :following_tags_count, presence: true
  validates :following_users_count, presence: true
  validates :name, length: { in: 1..100 }, presence: true
  validates :password, length: { in: 8..100 }, allow_nil: true
  validates :rating_votes_count, presence: true
  validates :reactions_count, presence: true
  validates :sign_in_count, presence: true
  validates :spent_credits_count, presence: true
  validates :subscribed_to_user_subscriptions_count, presence: true
  validates :unspent_credits_count, presence: true
  validates :reputation_modifier, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 },
                                  presence: true

  # add validators for provider related usernames
  Authentication::Providers.username_fields.each do |username_field|
    # make sure usernames are not empty string, to be able to use the database unique index
    clean_provider_username = proc do |record|
      cleaned_username = record.attributes[username_field.to_s].presence
      record.assign_attributes(username_field => cleaned_username)
    end
    before_validation clean_provider_username

    validates username_field, uniqueness: { allow_nil: true }, if: :"#{username_field}_changed?"
  end

  validate :non_banished_username, :username_changed?

  unique_across_models :username, length: { in: 2..USERNAME_MAX_LENGTH }

  validate :can_send_confirmation_email
  validate :update_rate_limit
  # NOTE: when updating the password on a Devise enabled model, the :encrypted_password
  # field will be marked as dirty, not :password.
  validate :password_matches_confirmation, if: :encrypted_password_changed?

  alias_attribute :public_reactions_count, :reactions_count

  scope :eager_load_serialized_data, -> { includes(:roles) }
  scope :registered, -> { where(registered: true) }
  scope :invited, -> { where(registered: false) }
  # Unfortunately pg_search's default SQL query is not performant enough in this
  # particular case (~ 500ms). There are multiple reasons:
  # => creates a complex query like `SELECT FROM users INNER JOIN users` to compute ranking.
  #    See https://github.com/Casecommons/pg_search/issues/292#issuecomment-202604151
  # => it concatenates the content of `name` and the content of `username` to match
  #    against the search term. By doing that, it can't use `tsvector` indexes correctly
  #
  # For these reasons we need to build a query manually using an `OR` condition,
  # thus allowing the database to use the indexes properly. With this the SQL time is ~ 8-10ms.
  #
  # NOTE: we can't use unaccent() on the `tsvector` document because `unaccent()` can't be
  # used in expression indexes as it's a mutable function and depends on server settings
  # => https://stackoverflow.com/a/11007216/4186181
  #
  scope :search_by_name_and_username, lambda { |term|
    term = term&.delete("\\") # prevents syntax error in tsquery
    return none if term.blank?

    where(
      sanitize_sql_array(
        [
          "to_tsvector('simple', coalesce(name::text, '')) @@ to_tsquery('simple', ? || ':*')",
          connection.quote(term),
        ],
      ),
    ).or(
      where(
        sanitize_sql_array(
          [
            "to_tsvector('simple', coalesce(username::text, '')) @@ to_tsquery('simple', ? || ':*')",
            connection.quote(term),
          ],
        ),
      ),
    )
  }

  scope :with_experience_level, lambda { |level = nil|
    includes(:setting).where("users_settings.experience_level": level)
  }

  scope :recently_active, lambda { |active_limit = RECENTLY_ACTIVE_LIMIT|
    order(updated_at: :desc).limit(active_limit)
  }

  scope :above_average, lambda {
    where(
      articles_count: average_articles_count..,
      comments_count: average_comments_count..,
    )
  }

  before_validation :downcase_email

  # make sure usernames are not empty, to be able to use the database unique index
  before_validation :set_username
  before_create :create_users_settings_and_notification_settings_records
  after_update :refresh_auto_audience_segments
  before_destroy :remove_from_mailchimp_newsletters, prepend: true
  before_destroy :destroy_follows, prepend: true

  after_create_commit :send_welcome_notification

  after_save :create_conditional_autovomits
  after_save :generate_social_images
  after_commit :subscribe_to_mailchimp_newsletter
  after_commit :bust_cache

  def self.average_articles_count
    Rails.cache.fetch("established_user_article_count", expires_in: 1.day) do
      unscoped { where(articles_count: 1..).average(:articles_count) || average(:articles_count) } || 0.0
    end
  end

  def self.average_comments_count
    Rails.cache.fetch("established_user_comment_count", expires_in: 1.day) do
      unscoped { where(comments_count: 1..).average(:comments_count) || average(:comments_count) } || 0.0
    end
  end

  def self.staff_account
    find_by(id: Settings::Community.staff_user_id)
  end

  def self.mascot_account
    find_by(id: Settings::General.mascot_user_id)
  end

  def good_standing_followers_count
    Follow.non_suspended("User", id).count
  end

  def tag_line
    profile.summary
  end

  def twitter_url
    "https://twitter.com/#{twitter_username}" if twitter_username.present?
  end

  def github_url
    "https://github.com/#{github_username}" if github_username.present?
  end

  def set_remember_fields
    self.remember_token ||= self.class.remember_token if respond_to?(:remember_token)
    self.remember_created_at ||= Time.now.utc
  end

  def set_initial_roles!
    # Avoid overwriting roles for users who already exist but are e.g. logging in
    # through a new identity provider
    return unless valid? && previously_new_record?

    if Settings::General.waiting_on_first_user
      add_role(:creator)
      add_role(:super_admin)
      add_role(:trusted)
    elsif Settings::Authentication.limit_new_users?
      add_role(:limited)
      # Otherwise just leave the new user in good standing
    end
  end

  def calculate_score
    # User score is used to mitigate spam by reducing visibility of flagged users
    # It can generally be used as a baseline for affecting certain functionality which
    # relies on trust gray area.

    # Current main use: If score is below zero, the user's profile page will render noindex
    # meta tag. This is a subtle anti-spam mechanism.

    # It can be changed as frequently as needed to do a better job reflecting its purpose
    # Changes should generally keep the score within the same order of magnitude so that
    # mass re-calculation is needed.
    user_reaction_points = Reaction.user_vomits.where(reactable_id: id).sum(:points)
    calculated_score = (badge_achievements_count * 10) + user_reaction_points
    calculated_score -= 500 if spam?
    update_column(:score, calculated_score)
    AlgoliaSearch::SearchIndexWorker.perform_async(self.class.name, id, false)
  end

  def path
    "/#{username}"
  end

  # NOTE: This method is only used in the EmailDigestArticleCollector and does
  # not perform particularly well. It should most likely not be used in other
  # parts of the app.
  def followed_articles
    relation = Article
    if cached_antifollowed_tag_names.any?
      relation = relation.not_cached_tagged_with_any(cached_antifollowed_tag_names)
    end

    relation
      .cached_tagged_with_any(cached_followed_tag_names)
      .unscope(:select)
      .union(Article.where(user_id: cached_following_users_ids))
  end

  def cached_followed_tag_names_or_recent_tags
    followed_tags = cached_followed_tag_names
    return followed_tags if followed_tags.any?

    ### pluck cached_tag_list for articles with most recent page views. Page views have a user_id and article_id
    ### cached_tag_list is a comma-separated string of tag names on the article

    cached_recent_pageview_article_ids = page_views.order("created_at DESC").limit(6).pluck(:article_id)
    tags = Article.where(id: cached_recent_pageview_article_ids).pluck(:cached_tag_list)
      .map { |list| list.split(", ") }
      .flatten.uniq.reject(&:empty?)
    tags + %w[career productivity ai git] # These are highly DEV-specific. Should be refactored later to be config'd
  end

  def cached_following_users_ids
    cache_key = "user-#{id}-#{last_followed_at}-#{following_users_count}/following_users_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_user(id).limit(150).pluck(:followable_id)
    end
  end

  def cached_following_organizations_ids
    cache_key = "user-#{id}-#{last_followed_at}-#{following_orgs_count}/following_organizations_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_organization(id).limit(150).pluck(:followable_id)
    end
  end

  def cached_following_podcasts_ids
    cache_key = "#{cache_key_with_version}/following_podcasts_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_podcast(id).pluck(:followable_id)
    end
  end

  def cached_reading_list_article_ids
    Rails.cache.fetch("reading_list_ids_of_articles_#{id}_#{public_reactions_count}_#{last_reacted_at}") do
      readinglist = Reaction.readinglist_for_user(self).order("created_at DESC")
      published = Article.published.where(id: readinglist.pluck(:reactable_id)).ids
      readinglist.filter_map { |r| r.reactable_id if published.include? r.reactable_id }
    end
  end

  def processed_website_url
    profile.website_url.to_s.strip if profile.website_url.present?
  end

  def remember_me
    true
  end

  def cached_followed_tag_names
    cache_name = "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}-x/followed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.followed_by(self).pluck(:name)
    end
  end

  def cached_antifollowed_tag_names
    cache_name = "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/antifollowed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.antifollowed_by(self).pluck(:name)
    end
  end

  def refresh_auto_audience_segments
    SegmentedUserRefreshWorker.perform_async(id)
  end

  ##############################################################################
  #
  # Heads Up: Start Authorization Refactor
  #
  ##############################################################################
  #
  # What's going on here?  First, I'm wanting to encourage folks to
  # not call these methods directly.  Instead I want to get all of
  # these method calls in a single location so we can begin to analyze
  # the behavior.

  # @api private
  #
  # The method originally comes from the Rollify gem.  Please don't
  # call it from controllers or views.  Favor `user.tech_admin?` over
  # `user.has_role?(:tech_admin)`.
  #
  # @see Authorizer for further discussion.
  private :has_role?

  ##
  # @api private
  #
  # The method originally comes from the Rollify gem.  Please don't
  # call it from controllers or views.  Favor `user.admin?` over
  # `user.has_any_role?(:admin)`.
  #
  # @see Authorizer for further discussion.
  private :has_any_role?

  ##
  # @api private
  #
  # This is a refactoring step to help move the role questions out of the user object.
  #
  # @see https://github.com/forem/forem/issues/15624 for more discussion.
  def authorizer
    @authorizer ||= Authorizer.for(user: self)
  end

  # My preference is to go with:
  #
  #   `Authorize.for(user: user, to: <action>, on: <subject>)`
  #
  # However, this is a refactor, and its goal is to reduce the direct
  # calls to user.<role question>.
  delegate(
    :admin?,
    :administrative_access_to?,
    :any_admin?,
    :auditable?,
    :augmented?,
    :banished?,
    :comment_suspended?,
    :limited?,
    :creator?,
    :has_trusted_role?,
    :super_moderator?,
    :podcast_admin_for?,
    :restricted_liquid_tag_for?,
    :single_resource_admin_for?,
    :super_admin?,
    :support_admin?,
    :suspended?,
    :spam?,
    :spam_or_suspended?,
    :tag_moderator?,
    :tech_admin?,
    :trusted?,
    :user_subscription_tag_available?,
    :vomited_on?,
    :warned?,
    to: :authorizer,
  )
  alias suspended suspended?
  alias spam spam?
  ##############################################################################
  #
  # End Authorization Refactor
  #
  ##############################################################################

  # The name of the tags moderated by the user.
  #
  # @note This caches a relatively expensive query
  #
  # @return [Array<String>] an array of tag names
  #
  # @see #moderator_for_tags_not_cached
  def moderator_for_tags
    Rails.cache.fetch("user-#{id}/tag_moderators_list", expires_in: 200.hours) do
      moderator_for_tags_not_cached
    end
  end

  # When you need the "up to the moment" names of the tags moderated
  # by this user.
  #
  # @note Favor #moderator_for_tags
  #
  # @return [Array<String>] an array of tag names
  #
  # @see #moderator_for_tags
  def moderator_for_tags_not_cached
    tag_ids = roles.where(name: "tag_moderator").pluck(:resource_id)
    Tag.where(id: tag_ids).pluck(:name)
  end

  def admin_organizations
    org_ids = organization_memberships.admin.pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def member_organizations
    org_ids = organization_memberships.member.pluck(:organization_id)
    organizations.where(id: org_ids)
  end

  def org_member?(organization)
    organization_memberships.member.exists?(organization: organization)
  end

  def org_admin?(organization)
    organization_memberships.admin.exists?(organization: organization)
  end

  def block; end

  def all_blocked_by
    UserBlock.where(blocked_id: id)
  end

  def blocking?(blocked_id)
    UserBlock.blocking?(id, blocked_id)
  end

  def blocked_by?(blocker_id)
    UserBlock.blocking?(blocker_id, id)
  end

  def non_banished_username
    errors.add(:username, I18n.t("models.user.has_been_banished")) if BanishedUser.exists?(username: username)
  end

  def subscribe_to_mailchimp_newsletter
    return unless registered && email.present?
    return if Settings::General.mailchimp_api_key.blank?
    return if saved_changes.key?(:unconfirmed_email) && saved_changes.key?(:confirmation_sent_at)
    return unless saved_changes.key?(:email)

    Users::SubscribeToMailchimpNewsletterWorker.perform_async(id)
  end

  def profile_image_90
    profile_image_url_for(length: 90)
  end

  def remove_from_mailchimp_newsletters
    return if email.blank?
    return if Settings::General.mailchimp_api_key.blank?

    Mailchimp::Bot.new(self).remove_from_mailchimp
  end

  def enough_credits?(num_credits_needed)
    credits.unspent.size >= num_credits_needed
  end

  def receives_follower_email_notifications?
    email.present? && notification_setting.subscribed_to_email_follower_notifications?
  end

  def authenticated_through?(provider_name)
    return false unless Authentication::Providers.available?(provider_name)
    return false unless Authentication::Providers.enabled?(provider_name)

    identities_enabled.exists?(provider: provider_name)
  end

  def authenticated_with_all_providers?
    # ga_providers refers to Generally Available (not in beta)
    ga_providers = Authentication::Providers.enabled.reject { |sym| sym == :apple }
    enabled_providers = identities.pluck(:provider).map(&:to_sym)
    (ga_providers - enabled_providers).empty?
  end

  def rate_limiter
    RateLimitChecker.new(self)
  end

  def flipper_id
    "User:#{id}"
  end

  def reactions_to
    Reaction.for_user(self)
  end

  def last_activity
    return unless registered == true

    [registered_at, last_comment_at, last_article_at, latest_article_updated_at, last_reacted_at, profile_updated_at,
     last_moderation_notification, last_notification_activity].compact.max
  end

  def currently_following_tags
    Tag.followed_by(self)
  end

  def has_no_published_content?
    articles.published.empty? && comments_count.zero?
  end

  protected

  # Send emails asynchronously
  # see https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *args)
    message = devise_mailer.public_send(notification, self, *args)
    message.deliver_later
  end

  private

  def generate_social_images
    change = saved_change_to_attribute?(:name) || saved_change_to_attribute?(:profile_image)
    return unless change && articles.published.size.positive?

    Images::SocialImageWorker.perform_async(id, self.class.name)
  end

  def create_users_settings_and_notification_settings_records
    self.setting = Users::Setting.create
    self.notification_setting = Users::NotificationSetting.create
  end

  def send_welcome_notification
    return unless (set_up_profile_broadcast = Broadcast.active.find_by(title: "Welcome Notification: set_up_profile"))

    Notification.send_welcome_notification(id, set_up_profile_broadcast.id)
  end

  def set_username
    self.username = username&.downcase.presence || generate_username
  end

  def auth_provider_usernames
    attributes
      .with_indifferent_access
      .slice(*Authentication::Providers.username_fields)
      .values.compact || []
  end

  def generate_username
    Users::UsernameGenerator
      .call(auth_provider_usernames)
  end

  def downcase_email
    self.email = email.downcase if email
  end

  def bust_cache
    Users::BustCacheWorker.perform_async(id)
  end

  def create_conditional_autovomits
    Spam::Handler.handle_user!(user: self)
  end

  def destroy_follows
    follower_relationships = Follow.followable_user(id)
    follower_relationships.destroy_all
    follows.destroy_all
  end

  def can_send_confirmation_email
    return if changes[:email].blank? || id.blank?

    rate_limiter.track_limit_by_action(:send_email_confirmation)
    rate_limiter.check_limit!(:send_email_confirmation)
  rescue RateLimitChecker::LimitReached => e
    errors.add(:email, I18n.t("models.user.could_not_send", e_message: e.message))
  end

  def update_rate_limit
    return unless persisted?

    rate_limiter.track_limit_by_action(:user_update)
    rate_limiter.check_limit!(:user_update)
  rescue RateLimitChecker::LimitReached => e
    errors.add(:base, I18n.t("models.user.user_could_not_be_saved", e_message: e.message))
  end

  def password_matches_confirmation
    return true if password == password_confirmation

    errors.add(:password, I18n.t("models.user.password_not_matched"))
  end

  def confirmation_required?
    ForemInstance.smtp_enabled?
  end

  def update_user_roles_cache(...)
    authorizer.clear_cache
    Rails.cache.delete("user-#{id}/has_trusted_role")
    refresh_auto_audience_segments
    trusted?
  end
end
