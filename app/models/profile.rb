class Profile < ApplicationRecord
  SUMMARY_ATTRIBUTE = "summary".freeze
  MAX_SUMMARY_LENGTH = 200

  belongs_to :user

  validates :data, presence: true
  validates :user_id, uniqueness: true

  # NOTE: @citizen428 The summary is a base profile field, which we add to all
  # new Forem instances, so it should be save to validate. The method itself
  # also guards against the field's absence.
  validate :conditionally_validate_summary

  has_many :custom_profile_fields, dependent: :destroy

  store_attribute :data, :custom_attributes, :json, default: {}

  # NOTE: @citizen428 This is a temporary mapping so we don't break DEV during
  # profile migration/generalization work.
  MAPPED_ATTRIBUTES = {
    brand_color1: :bg_color_hex,
    brand_color2: :text_color_hex,
    display_email_on_profile: :email_public,
    display_looking_for_work_on_profile: :looking_for_work_publicly,
    git_lab_url: :gitlab_url,
    linked_in_url: :linkedin_url,
    recruiters_can_contact_me_about_job_opportunities: :contact_consent,
    stack_overflow_url: :stackoverflow_url
  }.with_indifferent_access.freeze

  # Generates typed accessors for all currently defined profile fields.
  def self.refresh_attributes!
    ProfileField.find_each do |field|
      store_attribute :data, field.attribute_name.to_sym, field.type
    end
  end

  # Returns an array of all currently defined `store_attribute`s on `data`.
  def self.attributes
    (stored_attributes[:data] || []).map(&:to_s)
  end

  # Forces a reload before returning attributes
  def self.attributes!
    refresh_attributes!
    attributes
  end

  # NOTE: @citizen428 This is a temporary mapping so we don't break DEV during
  # profile migration/generalization work.
  def self.mapped_attributes
    attributes!.map { |attribute| MAPPED_ATTRIBUTES.fetch(attribute, attribute).to_s }
  end

  # NOTE: @citizen428 We want to have a current list of profile attributes the
  # moment the application loads. However, doing this unconditionally fails if
  # the profiles table doesn't exist yet (e.g. when running bin/setup in a new
  # clone). I wish Rails had a hook for code to run after the app started, but
  # for now this is the best I can come up with.
  refresh_attributes! if ApplicationRecord.connection.table_exists?("profiles")

  def custom_profile_attributes
    custom_profile_fields.pluck(:attribute_name)
  end

  def clear!
    update(data: {})
  end

  private

  def conditionally_validate_summary
    return unless summary.present? && ProfileField.exists?(attribute_name: SUMMARY_ATTRIBUTE)
    # Grandfather in people who had a too long summary before.
    return if data_was[SUMMARY_ATTRIBUTE] && data_was[SUMMARY_ATTRIBUTE].size > MAX_SUMMARY_LENGTH

    errors.add(:summary, "is too long.") if summary.size > MAX_SUMMARY_LENGTH
  end
end
