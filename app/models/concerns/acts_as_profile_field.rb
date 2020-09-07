# Used for sharing behavior between ProfileField and CustomProfileField
concern :ActsAsProfileField do
  included do
    before_create :generate_attribute_name

    WORD_REGEX = /\w+/.freeze

    validates :label, presence: true, uniqueness: { case_sensitive: false }
    validates :attribute_name, presence: true, on: :update
  end

  private

  def generate_attribute_name
    self.attribute_name = label.titleize.scan(WORD_REGEX).join.underscore
  end
end
