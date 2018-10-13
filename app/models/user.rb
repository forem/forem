class User < ApplicationRecord
  include CloudinaryHelper

  attr_accessor :scholar_email, :add_mentor, :add_mentee, :mentorship_note, :ban_from_mentorship

  rolify
  include AlgoliaSearch
  include Storext.model

  acts_as_taggable_on :tags

  acts_as_followable
  acts_as_follower

  belongs_to  :organization, optional: true
  has_many    :articles, dependent: :destroy
  has_many    :badge_achievements, dependent: :destroy
  has_many    :badges, through: :badge_achievements
  has_many    :collections, dependent: :destroy
  has_many    :comments, dependent: :destroy
  has_many    :email_messages, class_name: "Ahoy::Message"
  has_many    :github_repos, dependent: :destroy
  has_many    :identities, dependent: :destroy
  has_many    :mentions, dependent: :destroy
  has_many    :messages, dependent: :destroy
  has_many    :notes, as: :noteable
  has_many    :authored_notes, as: :author, class_name: "Note"
  has_many    :notifications, dependent: :destroy
  has_many    :reactions, dependent: :destroy
  has_many    :tweets, dependent: :destroy
  has_many    :chat_channel_memberships, dependent: :destroy
  has_many    :chat_channels, through: :chat_channel_memberships
  has_many    :push_notification_subscriptions, dependent: :destroy
  has_many    :feedback_messages
  has_many :mentor_relationships_as_mentee,
  class_name: "MentorRelationship", foreign_key: "mentee_id"
  has_many :mentor_relationships_as_mentor,
  class_name: "MentorRelationship", foreign_key: "mentor_id"
  has_many :mentors,
  through: :mentor_relationships_as_mentee,
  source: :mentor
  has_many :mentees,
  through: :mentor_relationships_as_mentor,
  source: :mentee

  mount_uploader :profile_image, ProfileImageUploader

  devise :omniauthable, :rememberable,
        :registerable, :database_authenticatable, :confirmable
  validates :email,
            uniqueness: { allow_blank: true, case_sensitive: false },
            length: { maximum: 50 },
            email: true,
            allow_blank: true
  validates :name, length: { minimum: 1, maximum: 100 }
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9_]+\Z/ },
            length: { in: 2..30 },
            exclusion: { in: ReservedWords.all,
                         message: "%{value} is reserved." }
  validates :twitter_username, uniqueness: { allow_blank: true }
  validates :github_username, uniqueness: { allow_blank: true }
  validates :text_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true
  validates :bg_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true
  validates :website_url, url: { allow_blank: true, no_local: true, schemes: ["https", "http"] }
  # rubocop:disable Metrics/LineLength
  validates :facebook_url,
              format: /\Ahttps:\/\/(www.facebook.com|facebook.com)\/[a-zA-Z0-9.]{5,50}\/?\Z/,
              allow_blank: true
  validates :stackoverflow_url,
              allow_blank: true,
              format:
              /\Ahttps:\/\/(www.stackoverflow.com|stackoverflow.com|www.stackexchange.com|stackexchange.com)\/([\S]{3,100})\Z/
  validates :behance_url,
              allow_blank: true,
              format: /\Ahttps:\/\/(www.behance.net|behance.net)\/([a-zA-Z0-9\-\_]{3,20})\/?\Z/
  validates :linkedin_url,
              allow_blank: true,
              format:
                /\Ahttps:\/\/(www.linkedin.com|linkedin.com|[A-Za-z]{2}.linkedin.com)\/in\/([a-zA-Z0-9\-]{3,100})\/?\Z/
  validates :dribbble_url,
              allow_blank: true,
              format: /\Ahttps:\/\/(www.dribbble.com|dribbble.com)\/([a-zA-Z0-9\-\_]{2,20})\/?\Z/
  # rubocop:enable Metrics/LineLength
  validates :employer_url, url: { allow_blank: true, no_local: true, schemes: ["https", "http"] }
  validates :shirt_gender,
              inclusion: { in: %w(unisex womens),
                           message: "%{value} is not a valid shirt style" },
              allow_blank: true
  validates :shirt_size,
              inclusion: { in: %w(xs s m l xl 2xl 3xl 4xl),
                           message: "%{value} is not a valid size" },
              allow_blank: true
  validates :tabs_or_spaces,
              inclusion: { in: %w(tabs spaces),
                           message: "%{value} is not a valid answer" },
              allow_blank: true
  validates :editor_version,
              inclusion: { in: %w(v1 v2),
                           message: "%{value} must be either v1 or v2" }
  validates :shipping_country,
              length: { in: 2..2 },
              allow_blank: true
  validates :website_url, url: { allow_blank: true, no_local: true, schemes: ["https", "http"] }
  validates :website_url, :employer_name, :employer_url,
              length: { maximum: 100 }
  validates :employment_title, :education, :location,
              length: { maximum: 100 }
  validates :mostly_work_with, :currently_learning,
            :currently_hacking_on, :available_for,
                length: { maximum: 500 }
  validates :mentee_description, :mentor_description,
              length: { maximum: 1000 }
  validate  :conditionally_validate_summary
  validate  :validate_feed_url
  validate  :unique_including_orgs

  after_create :send_welcome_notification
  after_save  :bust_cache
  after_save  :subscribe_to_mailchimp_newsletter
  after_save  :conditionally_resave_articles
  after_create :estimate_default_language!
  before_update :mentorship_status_update
  before_validation :set_username
  before_validation :downcase_email
  before_validation :check_for_username_change
  before_destroy :remove_from_algolia_index
  before_destroy :destroy_empty_dm_channels
  before_destroy :destroy_follows
  before_destroy :unsubscribe_from_newsletters

  algoliasearch per_environment: true, enqueue: :trigger_delayed_index do
    attribute :name
    add_index "searchables",
                  id: :index_id,
                  per_environment: true,
                  enqueue: :trigger_delayed_index do
      attribute :user do
        { username: user.username,
          name: user.username,
          profile_image_90: profile_image_90 }
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

  # Via https://github.com/G5/storext
  store_attributes :language_settings do
    estimated_default_language String
    prefer_language_en Boolean, default: true
    prefer_language_ja Boolean, default: false
    prefer_language_es Boolean, default: false
    prefer_language_fr Boolean, default: false
    prefer_language_it Boolean, default: false
  end

  def self.trigger_delayed_index(record, remove)
    if remove
      record.delay.remove_from_index! if record&.persisted?
    else
      record.delay.index!
    end
  end

  def tag_line
    summary
  end

  def index_id
    "users-#{id}"
  end

  def estimate_default_language!
    identity = identities.where(provider: "twitter").first
    if email.end_with?(".jp")
      update(estimated_default_language: "ja", prefer_language_ja: true)
    elsif identity
      lang = identity.auth_data_dump["extra"]["raw_info"]["lang"]
      update(:estimated_default_language => lang,
             "prefer_language_#{lang}" => true)
    end
  end
  handle_asynchronously :estimate_default_language!

  def calculate_score
    score = (articles.where(featured: true).size * 100) + comments.sum(:score)
    update_column(:score, score)
  end

  def path
    "/" + username.to_s
  end

  def followed_articles
    Article.tagged_with(cached_followed_tag_names, any: true).union(
      Article.where(
        user_id: cached_following_users_ids,
      ),
    ).where(language: cached_preferred_langs, published: true)
  end

  def cached_following_users_ids
    Rails.cache.fetch(
      "user-#{id}-#{updated_at}-#{following_users_count}/following_users_ids",
      expires_in: 120.hours,
    ) do

      # More efficient query. May not cover future edge cases.
      # Should probably only return users who have published lately
      # But this should be okay for most for now.
      Follow.where(follower_id: id, followable_type: "User").limit(150).pluck(:followable_id)
    end
  end

  def cached_preferred_langs
    Rails.cache.fetch("user-#{id}-#{updated_at}/cached_preferred_langs", expires_in: 80.hours) do
      langs = []
      langs << "en" if prefer_language_en
      langs << "ja" if prefer_language_ja
      langs << "es" if prefer_language_es
      langs << "fr" if prefer_language_fr
      langs << "it" if prefer_language_it
      langs
    end
  end

  def processed_website_url
    if website_url.present?
      website_url.to_s.strip
    end
  end

  def remember_me
    true
  end

  def cached_followed_tag_names
    cache_name = "user-#{id}-#{updated_at}/followed_tag_names"
    Rails.cache.fetch(cache_name, expires_in: 100.hours) do
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

  def banned_from_mentorship
    has_role? :banned_from_mentorship
  end

  def admin?
    has_role?(:super_admin)
  end

  def trusted
    Rails.cache.fetch("user-#{id}/has_trusted_role", expires_in: 200.hours) do
      has_role? :trusted
    end
  end

  def reason_for_ban
    return if notes.where(reason: "banned").blank?
    Note.find_by(noteable_id: id, noteable_type: "User", reason: "banned").content
  end

  def reason_for_warning
    return if notes.where(reason: "warned").blank?
    Note.find_by(noteable_id: id, noteable_type: "User", reason: "warned").content
  end

  def scholar
    valid_pass = workshop_expiration.nil? || workshop_expiration > Time.now
    has_role?(:workshop_pass) && valid_pass
  end

  def analytics
    has_role? :analytics_beta_tester
  end

  def workshop_eligible?
    has_any_role?(:workshop_pass, :level_3_member, :level_4_member, :triple_unicorn_member)
  end

  def org_admin?(organization)
    user.org_admin && user.organization_id == organization.id
  end

  def unique_including_orgs
    errors.add(:username, "is taken.") if Organization.find_by_slug(username)
  end

  def subscribe_to_mailchimp_newsletter
    return unless email.present? && email.include?("@")

    if saved_changes["unconfirmed_email"] && saved_changes["confirmation_sent_at"]
      # This is when user is updating their email. There
      # is no need to update mailchimp until email is confirmed.
      return
    else
      MailchimpBot.new(self).upsert
    end
  end
  handle_asynchronously :subscribe_to_mailchimp_newsletter

  def can_view_analytics?
    has_any_role?(:super_admin, :analytics_beta_tester)
  end

  def a_sustaining_member?
    monthly_dues.positive?
  end

  def resave_articles
    cache_buster = CacheBuster.new
    articles.each do |article|
      cache_buster.bust(article.path)
      cache_buster.bust(article.path + "?i=i")
      article.save
    end
  end

  def settings_tab_list
    tab_list = %w(
      Profile
      Mentorship
      Integrations
      Notifications
      Publishing\ from\ RSS
      Organization
      Billing
    )
    tab_list << "Membership" if monthly_dues&.positive? && stripe_id_code
    tab_list << "Switch Organizations" if has_role?(:switch_between_orgs)
    tab_list.push("Account", "Misc")
  end

  def profile_image_90
    ProfileImage.new(self).get(90)
  end

  private

  def send_welcome_notification
    Broadcast.send_welcome_notification(id)
  end

  def set_username
    if username.blank?
      set_temp_username
    end
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
    User.find_by_username(temp_username) || Organization.find_by_slug(temp_username)
  end

  def temp_username
    if twitter_username
      twitter_username.downcase.gsub(/[^0-9a-z_]/i, "").gsub(/ /, "")
    elsif github_username
      github_username.downcase.gsub(/[^0-9a-z_]/i, "").gsub(/ /, "")
    end
  end

  def downcase_email
    self.email = email.downcase if email
  end

  def check_for_username_change
    if username_changed?
      self.old_old_username = old_username
      self.old_username = username_was
      chat_channels.find_each do |c|
        c.slug = c.slug.gsub(username_was, username)
        c.save
      end
      articles.find_each do |a|
        a.path = a.path.gsub(username_was, username)
        a.save
      end
    end
  end

  def conditionally_resave_articles
    if core_profile_details_changed?
      delay.resave_articles
    end
  end

  def bust_cache
    CacheBuster.new.bust("/#{username}")
    CacheBuster.new.bust("/feed/#{username}")
  end
  handle_asynchronously :bust_cache

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
    if summary.present? && summary.size > 200
      errors.add(:summary, "is too long.")
    end
  end

  def validate_feed_url
    return unless feed_url.present?
    errors.add(:feed_url, "is not a valid rss feed") unless RssReader.new.valid_feed_url?(feed_url)
  end

  def title
    name
  end

  def tag_list
    cached_followed_tag_names
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
    ActionView::Base.full_sanitizer.sanitize(
      comments.last(2).pluck(:body_markdown).join(" "),
    )[0..2500]
  end

  def body_text
    summary.to_s + ActionView::Base.full_sanitizer.
      sanitize(articles.last(50).
        pluck(:processed_html).
        join(" "))[0..2500]
  end

  def tag_keywords_for_search
    employer_name.to_s + mostly_work_with.to_s + available_for.to_s
  end

  def hotness_score
    search_score
  end

  def search_score
    article_score = (articles_count + comments_count + reactions_count) * 10
    score = (article_score + tag_keywords_for_search.size) * reputation_modifier * followers_count
    score.to_i
  end

  def remove_from_algolia_index
    remove_from_index!
    index = Algolia::Index.new("searchables_#{Rails.env}")
    index.delay.delete_object("users-#{id}")
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

  def unsubscribe_from_newsletters
    MailchimpBot.new(self).unsubscribe_all_newsletters
  end

  def mentorship_status_update
    if mentor_description_changed? || offering_mentorship_changed?
      self.mentor_form_updated_at = Time.now
    end

    if mentee_description_changed? || seeking_mentorship_changed?
      self.mentee_form_updated_at = Time.now
    end
  end
end
