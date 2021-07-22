class ProfileField < ApplicationRecord
  WORD_REGEX = /\b\w+\b/.freeze

  # Key names follow the Rails form helpers
  enum input_type: {
    text_field: 0,
    text_area: 1,
    check_box: 2
  }

  enum display_area: {
    header: 0,
    left_sidebar: 1,
    settings_only: 2
  }

  belongs_to :profile_field_group, optional: true

  validates :attribute_name, presence: true, on: :update
  validates :display_area, presence: true
  validates :input_type, presence: true
  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :show_in_onboarding, inclusion: { in: [true, false] }

  before_create :generate_attribute_name

  def type
    return :boolean if check_box?

    :string
  end

  private

  def generate_attribute_name
    self.attribute_name = label.titleize.scan(WORD_REGEX).join.underscore
  end
end
