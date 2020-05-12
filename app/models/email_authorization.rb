class EmailAuthorization < ApplicationRecord
  before_create :generate_confirmation_token
  belongs_to :user

  TYPES = %w[merge_request account_lockout uuid_issue account_ownership].freeze
  # uuid_issue is a specific case where a user deletes their old auth account and recreates it, leaving us with the incorrect uuid

  validates :type_of, presence: true
  validates :type_of, inclusion: { in: TYPES }

  alias_attribute :sent_at, :created_at

  private

  def generate_confirmation_token
    return if confirmation_token.present?

    self.confirmation_token = SecureRandom.urlsafe_base64
  end
end
