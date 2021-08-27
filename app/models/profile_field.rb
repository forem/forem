class ProfileField < ApplicationRecord
  WORD_REGEX = /\b\w+\b/

  HEADER_FIELD_LIMIT = 3
  HEADER_LIMIT_MESSAGE = "maximum number of header fields (#{HEADER_FIELD_LIMIT}) exceeded".freeze

  # Key names follow the Rails form helpers
  enum input_type: {
    text_field: 0,
    text_area: 1,
    check_box: 2
  }

  enum display_area: {
    header: 0,
    left_sidebar: 1
  }

  belongs_to :profile_field_group, optional: true

  validates :attribute_name, presence: true, on: :update
  validates :display_area, presence: true
  validates :input_type, presence: true
  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :show_in_onboarding, inclusion: { in: [true, false] }
  validate :maximum_header_field_count

  before_create :generate_attribute_name

  def type
    return :boolean if check_box?

    :string
  end

  private

  def generate_attribute_name
    self.attribute_name = label.titleize.scan(WORD_REGEX).join.underscore
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
