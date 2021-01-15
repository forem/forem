module Search
  module Postgres
    class ChatChannel
      MEMBERSHIP_STATUSES = %w[active joining_request].freeze

      # NOTE: this is "kinda" working. To test this load the console and compare:
      # 1 - `Search::ChatChannelMembership.search_documents(params: {channel_text: NAME_OF_ORG})`
      # => vs `Search::Postgres::ChatChannel.search_documents(NAME_OF_ORG)`
      # 2 - `Search::ChatChannelMembership.search_documents(params: {channel_text: NAME_OF_USER})`
      # => vs `Search::Postgres::ChatChannel.search_documents(NAME_OF_USER)`
      # You will see that the number of returned items is the same for both, the difference is that the
      # ES based index contains a lot more info which is stored at indexing time related to membership
      # but we don't have that info inside the DB so we need to use a serializer to get it
      # Also, the JS layer kinda expects a ChatChannelMembership row, not a ChatChannel
      def self.search_documents(term, channel_type: nil, status: nil, user_ids: [], page: 1, per_page: 30)
        page = (page || 1).to_i
        per_page = (per_page || 30).to_i

        membership_params = { status: MEMBERSHIP_STATUSES }
        membership_params.merge(user_ids: user_ids) if user_ids.present?

        relation = ::ChatChannel
          .joins(:active_memberships)
          .where(active_memberships_chat_channels: membership_params)

        relation = relation.where(channel_type: channel_type) if channel_type.present?
        relation = relation.where(status: status) if status.present?

        documents = relation
          .search_by_name_and_members(term)
          .order(last_message_at: :desc)
          .select(:channel_name, :channel_type, :discoverable, :id, :last_message_at, :slug, :status)
          .page(page)
          .per(per_page)

        Search::Postgres::ChatChannelSerializer.new(documents).serializable_hash.as_json["data"] || []
      end
    end
  end
end
