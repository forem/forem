class ProMembership < ApplicationRecord
  STATUSES = %w[active expired].freeze
  MONTHLY_COST = 5
  MONTHLY_COST_USD = 25

  belongs_to :user

  validates :user, :status, :expiration_notifications_count, presence: true
  validates :user, uniqueness: true
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
    update_columns(
      expires_at: 1.month.from_now,
      status: :active,
      expiration_notification_at: nil,
      expiration_notifications_count: 0,
    )
  end

  private

  def set_expiration_date
    self.expires_at = 1.month.from_now
  end
end
