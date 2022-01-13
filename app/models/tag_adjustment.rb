class TagAdjustment < ApplicationRecord
  validates :tag_name, presence: true, uniqueness: { scope: :article_id, message: "can't be an already adjusted tag" }
  validates :reason_for_adjustment, presence: true
  validates :adjustment_type, inclusion: { in: %w[removal addition] }, presence: true
  validates :status, inclusion: { in: %w[committed pending committed_and_resolvable resolved] }, presence: true
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  validate :user_permissions
  validate :article_tag_list

  belongs_to :user
  belongs_to :tag
  belongs_to :article

  private

  def user_permissions
    errors.add(:user_id, "does not have privilege to adjust these tags") unless has_privilege_to_adjust?
  end

  def has_privilege_to_adjust?
    return false unless user

    user.tag_moderator?(tag: tag) || user.any_admin?
  end

  def article_tag_list
    if adjustment_type == "removal" && article.tag_list.none? do |tag|
         tag.casecmp(tag_name).zero?
       end
      errors.add(:tag_id,
                 "selected for removal is not a current live tag.")
    end
    errors.add(:base, "4 tags max per article.") if adjustment_type == "addition" && article.tag_list.count > 3
  end
end
