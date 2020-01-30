module Api
  module V0
    class ChatChannelsController < ApiController
      def show
        @chat_channel = ChatChannel.
          select(SHOW_ATTRIBUTES_FOR_SERIALIZATION).
          find(params[:id])

        error_not_found unless @chat_channel.has_member?(current_user)
      end

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[id description channel_name].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION
    end
  end
end
