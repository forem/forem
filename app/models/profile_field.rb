class ProfileField < ApplicationRecord
  # Key names follow the Rails form helpers
  enum input_type: {
    text_field: 0,
    text_area: 1,
    check_box: 2,
    color_field: 3
  }

  validates :label, presence: true, uniqueness: { case_sensitive: false }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }

  def attribute_name
    label.titleize.delete(" ").underscore
  end

  def type
    return :boolean if check_box?

    :string
  end
end
