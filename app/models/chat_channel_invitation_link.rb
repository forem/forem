class ChatChannelInvitationLink < ApplicationRecord
  extend Enumerize

  enumerize :status, in: %w[expired active].freeze, predicates: true

  belongs_to :chat_channel

  validates :url, presence: true, uniqueness: true
  validates :expiry_time, presence: true
  validates :slug, uniqueness: true, presence: true
  validates :status, presence: true
end
