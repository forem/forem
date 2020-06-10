class EmailSubscription < ApplicationRecord
  ALLOWED_TYPES = %w[Article].freeze

  belongs_to :author, class_name: "User", foreign_key: :author_id, inverse_of: :email_subscriptions
  belongs_to :email_subscribable, polymorphic: true
  belongs_to :subscriber, class_name: "User", foreign_key: :subscriber_id, inverse_of: :email_subscriptions

  validates :author_id, presence: true
  validates :email_subscribable_id, presence: true
  validates :email_subscribable_type, presence: true, inclusion: { in: ALLOWED_TYPES }
  validates :subscriber_id, presence: true, uniqueness: { scope: %i[email_subscribable_type email_subscribable_id] }

  before_validation :set_author_id

  private

  def set_author_id
    return if author_id
    return unless email_subscribable

    # This to account for email_subscribable types that use a different field
    # name (i.e. admin_id instead of user_id), but the relationship is still
    # named User.
    #
    # If neither (user_id or user.id) are found, the author_id is nil and the
    # validation of presence on author_id above takes care of the rest. We'd
    # likely want to explicitly define the author when trying to create a
    # EmailSubscription in those cases.
    self.author_id = email_subscribable.try(:user_id) || email_subscribable.try(:user).try(:id)
  end
end
