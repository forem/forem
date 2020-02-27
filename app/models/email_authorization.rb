class EmailAuthorization < ApplicationRecord
  belongs_to :user

  TYPES = %w[merge_request account_lockout uuid_issue to_be_determined].freeze

  validates :json_data, :type_of, presence: true
  validates :type_of, inclusion: { in: TYPES }
  validates :user_id, uniqueness: { scope: %i[type_of] }

  alias_attribute :sent_at, :created_at
end
