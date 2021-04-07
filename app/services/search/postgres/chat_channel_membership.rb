module Search
  module Postgres
    class ChatChannelMembership
      ATTRIBUTES = %w[
        chat_channel_memberships.id
        chat_channel_memberships.chat_channel_id
        chat_channel_memberships.last_opened_at
        chat_channel_memberships.status
        chat_channel_memberships.user_id
        chat_channels.channel_name
        chat_channels.discoverable
        chat_channels.last_message_at
        chat_channels.slug
        chat_channels.status
        users.name
        users.profile_image
        users.username
      ].freeze
      private_constant :ATTRIBUTES

      # TODO: @mstruve: When we want to allow people like admins to search ALL
      # memberships this will need to change
      PERMITTED_STATUSES = %w[
        active
        joining_request
      ].freeze

      DEFAULT_PER_PAGE = 30
      private_constant :DEFAULT_PER_PAGE

      MAX_PER_PAGE = 60 # to avoid querying too many items, we set a maximum amount for a page
      private_constant :MAX_PER_PAGE

      def self.search_documents(user_ids:, page: 0, per_page: DEFAULT_PER_PAGE)
        # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::ChatChannelMembership
          .includes(:user, chat_channel: :messages)
          .where("chat_channel_memberships.status": PERMITTED_STATUSES)
          .where("chat_channel_memberships.user_id": user_ids)
          .select(*ATTRIBUTES)
          .order("chat_channels.last_message_at desc")

        results = relation.page(page).per(per_page)

        serialize(results)
      end

      def self.serialize(results)
        Search::ChatChannelMembershipSerializer
          .new(results, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
