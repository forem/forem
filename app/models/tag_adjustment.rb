class TagAdjustment < ApplicationRecord
  validates :user_id, presence: true
  validates :article_id, presence: true
  validates :tag_id, presence: true
  validates :tag_name, presence: true, uniqueness: { scope: :article_id, message: "can't be an already adjusted tag" }
  validates :reason_for_adjustment, presence: true
  validates :adjustment_type, inclusion: { in: %w[removal addition] }, presence: true
  validates :status, inclusion: { in: %w[committed pending committed_and_resolvable resolved] }, presence: true
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  validate :user_permissions
  validate :removal_tag_exists_on_article

  belongs_to :user
  belongs_to :tag
  belongs_to :article

  private

  def user_permissions
    errors.add(:user_id, "does not have privilege to adjust these tags") unless has_privilege_to_adjust?
  end

  def has_privilege_to_adjust?
    user&.has_role?(:tag_moderator, tag) ||
      user&.has_role?(:admin) ||
      user&.has_role?(:super_admin)
  end

  def removal_tag_exists_on_article
    errors.add(:tag_id, "selected for removal is not a current live tag") if adjustment_type == "removal" && article.tag_list.exclude?(tag_name)
  end
end
