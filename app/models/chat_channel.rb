class ChatChannel < ApplicationRecord
  has_many :messages

  validates :channel_type, presence: true, inclusion: { in: %w(open) }

  def clear_channel
    messages.each(&:destroy!)
    Pusher.trigger(id, "channel-cleared", [].to_json)
  rescue Pusher::Error => e
    logger.info "PUSHER ERROR: #{e.message}"
  end
end
