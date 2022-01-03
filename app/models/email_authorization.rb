class EmailAuthorization < ApplicationRecord
  belongs_to :user

  # uuid_issue is a specific case where a user deletes their old auth account and recreates it,
  # leaving us with the incorrect uuid
  TYPES = %w[merge_request account_lockout uuid_issue account_ownership].freeze

  validates :type_of, presence: true, inclusion: { in: TYPES }

  alias_attribute :sent_at, :created_at

  before_create :generate_confirmation_token

  def self.last_verification_date(user)
    user.email_authorizations
      .where.not(verified_at: nil)
      .order(created_at: :desc)
      .first
      &.verified_at
  end

  private

  def generate_confirmation_token
    return if confirmation_token.present?

    self.confirmation_token = SecureRandom.urlsafe_base64
  end
end
