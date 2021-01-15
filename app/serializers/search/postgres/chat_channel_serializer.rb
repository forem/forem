module Search
  module Postgres
    class ChatChannelSerializer < ApplicationSerializer
      attributes :id, :channel_name, :status, :last_message_at, :channel_type, :discoverable

      attributes :messages_count do |chat_channel|
        chat_channel.messages.count
      end

      attributes :memberships do |chat_channel|
        chat_channel.active_memberships.map do |membership|
          {
            last_opened_at: membership.last_opened_at,
            status: membership.status,
            user_id: membership.user_id,
            channel_username: membership.channel_username,
            channel_name: membership.channel_name,
            channel_image: membership.channel_image,
            channel_modified_slug: membership.channel_modified_slug
          }
        end
      end
    end
  end
end
