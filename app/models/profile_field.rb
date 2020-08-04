class ProfileField < ApplicationRecord
  # Key names follow the Rails form helpers
  INPUT_TYPES = {
    text_field: 0,
    text_area: 1,
    check_box: 2,
    color_field: 3
  }.freeze

  enum input_type: INPUT_TYPES

  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :active, inclusion: { in: [true, false] }
end
