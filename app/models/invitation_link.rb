class InvitationLink < ApplicationRecord
  belongs_to :chat_channel

  STATUSES = { active: 0, expired: 1 }.freeze

  enum status: STATUSES

  validates :path, presence: true
  validates :expiry_at, presence: true
  validates :slug, uniqueness: true, presence: true
  validates :status, presence: true
end
