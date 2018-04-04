class ChatChannel < ApplicationRecord
  has_many :messages

  validates :channel_type, presence: true, inclusion: { in: %w(open) }
end
