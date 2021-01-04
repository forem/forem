class Profile < ApplicationRecord
  belongs_to :user

  validates :data, presence: true
  validates :user_id, uniqueness: true
  validates_with ProfileValidator

  has_many :custom_profile_fields, dependent: :destroy

  store_attribute :data, :custom_attributes, :json, default: {}

  SPECIAL_FUNCTIONALITY_ATTRIBUTES = %w[
    summary
    employment_title
    employer_name
    employer_url
    email_public
    location
    display_looking_for_work_on_profile
    brand_color1
    brand_color2
    looking_for_work
  ].freeze

  SPECIAL_SOCIAL_LINK_ATTRIBUTES = %w[
    twitter_url
    github_url
    facebook_url
    linkedin_url
    youtube_url
    instagram_url
    behance_url
    medium_url
    stackoverflow_url
    gitlab_url
    twitch_url
    mastodon_url
    website_url
  ].freeze

  # NOTE: @citizen428 This is a temporary mapping so we don't break DEV during
  # profile migration/generalization work.
  MAPPED_ATTRIBUTES = {
    brand_color1: :bg_color_hex,
    brand_color2: :text_color_hex,
    display_email_on_profile: :email_public,
    display_looking_for_work_on_profile: :looking_for_work_publicly,
    education: :education,
    git_lab_url: :gitlab_url,
    linked_in_url: :linkedin_url,
    recruiters_can_contact_me_about_job_opportunities: :contact_consent,
    skills_languages: :mostly_work_with,
    stack_overflow_url: :stackoverflow_url
  }.with_indifferent_access.freeze

  # Generates typed accessors for all currently defined profile fields.
  def self.refresh_attributes!
    return if ENV["ENV_AVAILABLE"] == "false"
    return unless Database.table_exists?("profiles")

    ProfileField.find_each do |field|
      store_attribute :data, field.attribute_name.to_sym, field.type
    end
  end

  # Set up all profile attributes when this class loads so all store_attribute
  # accessors get defined immediately.
  refresh_attributes!

  # Returns an array of all currently defined `store_attribute`s on `data`.
  def self.attributes
    (stored_attributes[:data] || []).map(&:to_s)
  end

  def self.special_attributes
    SPECIAL_FUNCTIONALITY_ATTRIBUTES + SPECIAL_SOCIAL_LINK_ATTRIBUTES
  end

  def self.special_social_link_attributes
    SPECIAL_SOCIAL_LINK_ATTRIBUTES.freeze
  end

  def custom_profile_attributes
    custom_profile_fields.pluck(:attribute_name)
  end

  def clear!
    update(data: {})
  end
end
