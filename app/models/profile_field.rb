class ProfileField < ApplicationRecord
  before_create :generate_attribute_name

  WORD_REGEX = /\w+/.freeze

  # Key names follow the Rails form helpers
  enum input_type: {
    text_field: 0,
    text_area: 1,
    check_box: 2,
    color_field: 3
  }

  enum display_area: {
    header: 0,
    left_sidebar: 1
  }

  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :attribute_name, presence: true, on: :update
  validates :show_in_onboarding, inclusion: { in: [true, false] }
  validates :group, presence: true

  def type
    return :boolean if check_box?

    :string
  end

  private

  def generate_attribute_name
    self.attribute_name = label.titleize.scan(WORD_REGEX).join.underscore
  end
end
