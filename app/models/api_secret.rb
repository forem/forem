#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class ApiSecret < ApplicationRecord
  has_secure_token :secret

  belongs_to :user

  validates :description, presence: true, length: { maximum: 300 }
  validate :user_api_secret_count

  private

  def user_api_secret_count
    return if user && user.api_secrets.count < 10

    errors.add(:user, I18n.t("models.api_secret.api_limit_reached"))
  end
end
