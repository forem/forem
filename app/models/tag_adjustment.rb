class TagAdjustment < ApplicationRecord
  validates :tag_name, presence: true,
                       uniqueness: { scope: :article_id, message: I18n.t("models.tag_adjustment.unique") }
  validates :adjustment_type, inclusion: { in: %w[removal addition] }, presence: true
  validates :status, inclusion: { in: %w[committed pending committed_and_resolvable resolved] }, presence: true
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  validate :user_permissions
  validate :admin_adjusted
  validate :article_tag_list

  belongs_to :user
  belongs_to :tag
  belongs_to :article

  private

  def user_permissions
    errors.add(:user_id, I18n.t("models.tag_adjustment.unpermitted")) unless has_privilege_to_adjust?
  end

  def admin_adjusted
    return if elevated_user?

    # Honestly I would like a better way of doing this that doesn't perform N+1
    # queries to check for admins, but that's something I can revisit
    possible_admins = User.joins(:tag_adjustments).where(
      tag_adjustments: {
        # There's probably a case sensitivity tripwire here
        tag_name: tag_name, article_id: article_id
      },
    )
    return unless possible_admins.any? { |user| user.any_admin? || user.super_moderator? }

    errors.add(:tag_id, I18n.t("models.tag_adjustment.#{adjustment_type}_conflicts_with_admin"))
  end

  def elevated_user?
    user.any_admin? || user.super_moderator?
  end

  def has_privilege_to_adjust?
    return false unless user

    user.tag_moderator?(tag: tag) || elevated_user?
  end

  def article_tag_list
    if adjustment_type == "removal" && article.tag_list.none? do |tag|
         tag.casecmp(tag_name).zero?
       end
      errors.add(:tag_id,
                 I18n.t("models.tag_adjustment.not_live"))
    end
    return unless adjustment_type == "addition" && article.tag_list.count > 3

    errors.add(:base, I18n.t("models.tag_adjustment.too_many_tags"))
  end
end
