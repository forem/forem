#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class ApiSecret < ApplicationRecord
  has_secure_token :secret

  belongs_to :user

  validates :description, presence: true, length: { maximum: 300 }
  validate :user_api_secret_count

  after_create_commit :clear_rack_attack_cache

  private

  def user_api_secret_count
    return if user && user.api_secrets.count < 10

    errors.add(:user, I18n.t("models.api_secret.api_limit_reached"))
  end

  def clear_rack_attack_cache
    admin_api_secret = User.joins(:roles)
      .exists?(roles: { name: Rack::Attack::ADMIN_ROLES }, users: { id: user_id })
    return unless admin_api_secret

    # ApiSecret that belongs to an admin should clear the Rack::Attack
    # cache so they can bypass API throttling immediately
    Rails.cache.delete(Rack::Attack::ADMIN_API_CACHE_KEY)
  end
end
