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
  after_save :resave_user_articles
  after_save :bust_cache

  def expired?
    expires_at <= Time.current
  end

  def active?
    expires_at > Time.current
  end

  def expire!
    update!(expires_at: Time.current, status: :expired)
  end

  def renew!
    update!(
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

  # if the membership is new or the user flips from expired to active and viceversa,
  # we need to resave all of the user's articles to make sure that the pro details
  # that are cached with them are refreshed
  def resave_user_articles
    if saved_change_to_created_at? ||
        saved_change_to_expires_at? ||
        saved_change_to_status?
      Users::ResaveArticlesWorker.perform_async(user.id)
    end
  end

  def bust_cache
    Rails.cache.delete("user-#{user.id}/has_pro_membership")
  end
end
