class ProMembership < ApplicationRecord
  STATUSES = %w[active expired].freeze
  MONTHLY_COST = 5

  belongs_to :user

  validates :user, :status, presence: true
  validates :expires_at, presence: true, on: :save
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: :active) }
  scope :expired, -> { where(status: :expired) }

  before_create :set_expiration_date

  def expired?
    expires_at <= Time.current
  end

  def active?
    expires_at > Time.current
  end

  def expire!
    update_columns(expires_at: Time.current, status: :expired)
  end

  def renew!
    update_columns(expires_at: 1.month.from_now, status: :active)
  end

  private

  def set_expiration_date
    self.expires_at = 1.month.from_now
  end
end
