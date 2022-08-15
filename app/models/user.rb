class User < ApplicationRecord
  resourcify
  rolify

  include CloudinaryHelper

  include Images::Profile.for(:profile_image_url)

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

  USERNAME_MAX_LENGTH = 30
  USERNAME_REGEXP = /\A[a-zA-Z0-9_]+\z/
  # follow the syntax in https://interledger.org/rfcs/0026-payment-pointers/#payment-pointer-syntax
  PAYMENT_POINTER_REGEXP = %r{
    \A                # start
    \$                # starts with a dollar sign
    ([a-zA-Z0-9\-.])+ # matches the hostname (ex ilp.uphold.com)
    (/[\x20-\x7F]+)?  # optional forward slash and identifier with printable ASCII characters
    \z
  }x

  attr_accessor :scholar_email, :new_note, :note_for_current_role, :user_status, :merge_user_id,
                :add_credits, :remove_credits, :add_org_credits, :remove_org_credits, :ip_address,
                :current_password

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
  has_many :display_ad_events, dependent: :delete_all
  has_many :email_authorizations, dependent: :delete_all
  has_many :email_messages, class_name: "Ahoy::Message", dependent: :destroy
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
  has_many :sponsorships, dependent: :delete_all

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
  validates :name, length: { in: 1..100 }
  validates :password, length: { in: 8..100 }, allow_nil: true
  validates :payment_pointer, format: PAYMENT_POINTER_REGEXP, allow_blank: true
  validates :rating_votes_count, presence: true
  validates :reactions_count, presence: true
  validates :sign_in_count, presence: true
  validates :spent_credits_count, presence: true
  validates :subscribed_to_user_subscriptions_count, presence: true
  validates :unspent_credits_count, presence: true
  validates :username, length: { in: 2..USERNAME_MAX_LENGTH }, format: USERNAME_REGEXP
  validates :username, presence: true, exclusion: {
    in: ReservedWords.all,
    message: proc { I18n.t("models.user.username_is_reserved") }
  }
  validates :username, uniqueness: { case_sensitive: false, message: lambda do |_obj, data|
    I18n.t("models.user.is_taken", username: (data[:value]))
  end }, if: :username_changed?

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
  validates :username, unique_cross_model_slug: true, if: :username_changed?
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
  before_validation :downcase_email

  # make sure usernames are not empty, to be able to use the database unique index
  before_validation :set_username
  before_validation :strip_payment_pointer
  before_create :create_users_settings_and_notification_settings_records
  before_destroy :remove_from_mailchimp_newsletters, prepend: true
  before_destroy :destroy_follows, prepend: true

  after_create_commit :send_welcome_notification

  after_save :create_conditional_autovomits
  after_commit :subscribe_to_mailchimp_newsletter
  after_commit :bust_cache

  def self.staff_account
    find_by(id: Settings::Community.staff_user_id)
  end

  def self.mascot_account
    find_by(id: Settings::General.mascot_user_id)
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
    update_column(:score, calculated_score)
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
    cache_key = "user-#{id}-#{last_followed_at}/following_podcasts_ids"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      Follow.follower_podcast(id).pluck(:followable_id)
    end
  end

  def cached_reading_list_article_ids
    Rails.cache.fetch("reading_list_ids_of_articles_#{id}_#{public_reactions_count}_#{last_reacted_at}") do
      Reaction.readinglist.where(
        user_id: id, reactable_type: "Article",
      ).where.not(status: "archived").order(created_at: :desc).pluck(:reactable_id)
    end
  end

  def processed_website_url
    profile.website_url.to_s.strip if profile.website_url.present?
  end

  def remember_me
    true
  end

  # @todo Move the Query logic into Tag.  It represents User understanding the inner working of Tag.
  def cached_followed_tag_names
    cache_name = "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/followed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.where(
        id: Follow.where(
          follower_id: id,
          followable_type: "ActsAsTaggableOn::Tag",
          points: 1..,
        ).select(:followable_id),
      ).pluck(:name)
    end
  end

  # @todo Move the Query logic into Tag.  It represents User understanding the inner working of Tag.
  def cached_antifollowed_tag_names
    cache_name = "user-#{id}-#{following_tags_count}-#{last_followed_at&.rfc3339}/antifollowed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 24.hours) do
      Tag.where(
        id: Follow.where(
          follower_id: id,
          followable_type: "ActsAsTaggableOn::Tag",
          points: ...1,
        ).select(:followable_id),
      ).pluck(:name)
    end
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
    :banished?,
    :comment_suspended?,
    :creator?,
    :has_trusted_role?,
    :super_moderator?,
    :podcast_admin_for?,
    :restricted_liquid_tag_for?,
    :single_resource_admin_for?,
    :super_admin?,
    :support_admin?,
    :suspended?,
    :tag_moderator?,
    :tech_admin?,
    :trusted?,
    :user_subscription_tag_available?,
    :vomited_on?,
    :warned?,
    :workshop_eligible?,
    to: :authorizer,
  )
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
    email.present? && subscribed_to_email_follower_notifications?
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

  def subscribed_to_welcome_notifications?
    notification_setting.welcome_notifications
  end

  def subscribed_to_mod_roundrobin_notifications?
    notification_setting.mod_roundrobin_notifications
  end

  def subscribed_to_email_follower_notifications?
    notification_setting.email_follower_notifications
  end

  def reactions_to
    Reaction.for_user(self)
  end

  def last_activity
    return unless registered == true

    [registered_at, last_comment_at, last_article_at, latest_article_updated_at, last_reacted_at, profile_updated_at,
     last_moderation_notification, last_notification_activity].compact.max
  end

  protected

  # Send emails asynchronously
  # see https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *args)
    message = devise_mailer.public_send(notification, self, *args)
    message.deliver_later
  end

  private

  def create_users_settings_and_notification_settings_records
    self.setting = Users::Setting.create
    self.notification_setting = Users::NotificationSetting.create
  end

  def send_welcome_notification
    return unless (set_up_profile_broadcast = Broadcast.active.find_by(title: "Welcome Notification: set_up_profile"))

    Notification.send_welcome_notification(id, set_up_profile_broadcast.id)
  end

  def set_username
    set_temp_username if username.blank?
    self.username = username&.downcase
  end

  # @todo Should we do something to ensure that we don't create a username that violates our
  # USERNAME_MAX_LENGTH constant?
  #
  # @see USERNAME_MAX_LENGTH
  def set_temp_username
    self.username = if temp_name_exists?
                      "#{temp_username}_#{rand(100)}"
                    else
                      temp_username
                    end
  end

  def temp_name_exists?
    User.exists?(username: temp_username) || Organization.exists?(slug: temp_username)
  end

  def temp_username
    Authentication::Providers.username_fields.each do |username_field|
      value = public_send(username_field)
      next if value.blank?

      return value.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ")
    end
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

  def strip_payment_pointer
    self.payment_pointer = payment_pointer.strip if payment_pointer
  end

  def confirmation_required?
    ForemInstance.smtp_enabled?
  end
end
