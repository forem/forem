class ChatChannel < ApplicationRecord
  has_many :messages

  validates :channel_type, presence: true, inclusion: { in: %w(open invite_only) }

  def clear_channel
    messages.each(&:destroy!)
    Pusher.trigger(id, "channel-cleared", { chat_channel_id: id }.to_json)
    true
  rescue Pusher::Error => e
    logger.info "PUSHER ERROR: #{e.message}"
  end
end
