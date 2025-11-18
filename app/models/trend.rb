class Trend < ApplicationRecord
  belongs_to :subforem
  has_many :context_notes, dependent: :nullify

  validates :short_title, presence: true, length: { maximum: 75 }
  validates :public_description, presence: true
  validates :full_content_description, presence: true
  validates :expiry_date, presence: true

  scope :current, -> { where("expiry_date > ?", Time.current) }
  scope :for_subforem, ->(subforem_id) { where(subforem_id: subforem_id) }

  def expired?
    expiry_date < Time.current
  end

  def current?
    !expired?
  end
end

