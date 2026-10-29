class ProfileField < ApplicationRecord
  resourcify
  WORD_REGEX = /\b\w+\b/

  HEADER_FIELD_LIMIT = 3
  HEADER_LIMIT_MESSAGE = "maximum number of header fields (#{HEADER_FIELD_LIMIT}) exceeded".freeze

  # Key names follow the Rails form helpers
  enum :input_type, { text_field: 0, text_area: 1 }
  enum :display_area, { header: 0, left_sidebar: 1 }

  belongs_to :profile_field_group

  validates :attribute_name, presence: true, on: :update
  validates :display_area, presence: true
  validates :input_type, presence: true
  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :show_in_onboarding, inclusion: { in: [true, false] }
  validate :maximum_header_field_count

  before_create :generate_attribute_name
  after_destroy :clear_request_store_cache
  after_save :clear_request_store_cache

  # Loads every display area in one query so pages rendering both the header
  # and the left sidebar (e.g. profiles) only hit the table once per request.
  def self.cached_display_area_fields(area)
    fields_by_area = RequestStore.fetch(:profile_fields_by_display_area) do
      pluck(:display_area, :label, :attribute_name)
        .group_by(&:first)
        .transform_values { |rows| rows.to_h { |_display_area, label, attribute_name| [label, attribute_name] } }
    end
    fields_by_area.fetch(area.to_s, {})
  end

  def self.clear_request_store_cache
    RequestStore.store.delete_if { |key, _| key.to_s.start_with?("profile_fields_") }
  end

  private

  def clear_request_store_cache
    self.class.clear_request_store_cache
  end

  def generate_attribute_name
    self.attribute_name = "attribute_#{SecureRandom.hex}"
  end

  def maximum_header_field_count
    return unless header?

    header_field_count = self.class.header.count

    # We need to have less than the maximum number so we can still create one.
    if new_record? || display_area_was == "left_sidebar"
      return if header_field_count < HEADER_FIELD_LIMIT
    # We can change existing fields or update them as long as we're within the limit.
    elsif header_field_count <= HEADER_FIELD_LIMIT
      return
    end

    errors.add(:display_area, HEADER_LIMIT_MESSAGE)
  end
end
