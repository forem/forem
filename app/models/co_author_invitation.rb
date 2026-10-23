# An article author's request to credit another user as a co-author. The invitee confirms or
# declines from an on-platform notification. Accepting adds them to the article's co_author_ids,
# which stays the canonical list of credited co-authors.
#
# Only users who follow the author can be invited, and only to personal posts: organization
# posts keep using the org-admin co-author picker, which credits members directly.
#
# @note When we destroy the related article or user, it's using dependent: :destroy so the
#       invitation's notifications are cleaned up with it.
class CoAuthorInvitation < ApplicationRecord
  # Enforced over the whole invitee list by CoAuthorInvitations::Sync
  MAX_PER_ARTICLE = 4

  belongs_to :article
  # The invited co-author
  belongs_to :user

  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all

  enum :status, { pending: "pending", accepted: "accepted", declined: "declined" }, validate: true

  scope :active, -> { where(status: %w[pending accepted]) }

  validates :user_id, uniqueness: { scope: :article_id }
  validate :article_is_personal, on: :create
  validate :invitee_is_eligible, on: :create

  after_create_commit :send_invitation_notification

  # Users the author may invite: their followers, minus anyone either of them has blocked and
  # anyone suspended or marked as spam.
  #
  # @param author [User]
  # @return [ActiveRecord::Relation<User>]
  def self.eligible_invitees_for(author)
    follower_ids = Follow.followable_user(author.id).where(follower_type: "User", blocked: false).select(:follower_id)

    User.where(id: follower_ids)
      .where.not(id: author.id)
      .where.not(id: UserBlock.where(blocker_id: author.id).select(:blocked_id))
      .where.not(id: UserBlock.where(blocked_id: author.id).select(:blocker_id))
      .without_role(:suspended)
      .without_role(:spam)
  end

  private

  def article_is_personal
    return if article.nil? || article.organization_id.blank?

    errors.add(:base, I18n.t("models.co_author_invitation.personal_posts_only"))
  end

  def invitee_is_eligible
    # A missing article or user is already reported by belongs_to.
    return if article.nil? || user.nil?
    return if self.class.eligible_invitees_for(article.user).exists?(id: user_id)

    errors.add(:base, I18n.t("models.co_author_invitation.must_follow_author", username: user.username))
  end

  def send_invitation_notification
    Notification.send_co_author_invitation_notification(self)
  end
end
