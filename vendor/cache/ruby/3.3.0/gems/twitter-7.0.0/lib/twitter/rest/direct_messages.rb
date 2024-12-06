require 'twitter/arguments'
require 'twitter/direct_message'
require 'twitter/direct_message_event'
require 'twitter/rest/upload_utils'
require 'twitter/rest/utils'
require 'twitter/user'
require 'twitter/utils'

module Twitter
  module REST
    module DirectMessages
      include Twitter::REST::UploadUtils
      include Twitter::REST::Utils
      include Twitter::Utils

      # Returns all Direct Message events for the authenticated user (both sent and received) within the last 30 days. Sorted in reverse-chronological order.
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/list-events
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::DirectMessageEvent>] Direct message events sent by and received by the authenticating user.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :count Specifies the number of records to retrieve. Must be less than or equal to 50. Default is 20
      # @option options [String] :cursor Specifies the cursor position of results to retrieve.
      def direct_messages_events(options = {})
        limit = options.fetch(:count, 20)
        perform_get_with_cursor('/1.1/direct_messages/events/list.json', options.merge!(no_default_cursor: true, count: 50, limit: limit), :events, Twitter::DirectMessageEvent)
      end

      # Returns all Direct Messages for the authenticated user (both sent and received) within the last 30 days. Sorted in reverse-chronological order.
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/list-events
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::DirectMessage>] Direct messages sent by and received by the authenticating user.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :count Specifies the number of records to retrieve. Must be less than or equal to 50. Default is 20
      # @option options [String] :cursor Specifies the cursor position of results to retrieve.
      def direct_messages_list(options = {})
        direct_messages_events(options).collect(&:direct_message)
      end

      # Returns Direct Messages received by the authenticated user within the last 30 days. Sorted in reverse-chronological order.
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/list-events
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::DirectMessage>] Direct messages received by the authenticating user.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :count Specifies the number of records (sent and received dms) to retrieve. Must be less than or equal to 50. Default is 50
      # this count does not directly correspond to the output, as we pull sent and received messages from twitter and only present received to the user
      # @option options [String] :cursor Specifies the cursor position of results to retrieve.
      def direct_messages_received(options = {})
        limit = options.fetch(:count, 20)
        direct_messages_list(options).select { |dm| dm.recipient_id == user_id }.first(limit)
      end

      # Returns Direct Messages sent by the authenticated user within the last 30 days. Sorted in reverse-chronological order.
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/list-events
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::DirectMessage>] Direct messages sent by the authenticating user.
      # @param options [Hash] A customizable set of options.
      # @option options [Integer] :count Specifies the number of records (sent and received dms) to retrieve. Must be less than or equal to 50. Default is 50
      # this count does not directly correspond to the output, as we pull sent and received messages from twitter and only present received to the user
      # @option options [String] :cursor Specifies the cursor position of results to retrieve.
      def direct_messages_sent(options = {})
        limit = options.fetch(:count, 20)
        direct_messages_list(options).select { |dm| dm.sender_id == user_id }.first(limit)
      end

      # Returns a direct message
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/get-event
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::DirectMessage] The requested message.
      # @param id [Integer] A direct message ID.
      # @param options [Hash] A customizable set of options.

      def direct_message(id, options = {})
        direct_message_event(id, options).direct_message
      end

      # Returns a direct message event
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/get-event
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::DirectMessageEvent] The requested message.
      # @param id [Integer] A direct message ID.
      # @param options [Hash] A customizable set of options.
      def direct_message_event(id, options = {})
        options = options.dup
        options[:id] = id
        perform_get_with_object('/1.1/direct_messages/events/show.json', options, Twitter::DirectMessageEvent)
      end

      # Returns direct messages specified in arguments, or, if no arguments are given, returns direct messages received by authenticating user
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::DirectMessage>] The requested messages.
      # @overload direct_messages(options = {})
      #   Returns the 20 most recent direct messages sent to the authenticating user

      #   @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/list-events
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count Specifies the number of records (sent and received dms) to retrieve. Must be less than or equal to 50. Default is 50
      #   this count does not directly correspond to the output, as we pull sent and received messages from twitter and only present received to the user
      #   @option options [String] :cursor Specifies the cursor position of results to retrieve.
      # @overload direct_messages(*ids)
      #   Returns direct messages
      #
      #   @see https://dev.twitter.com/rest/reference/get/direct_messages/show
      #   @param ids [Enumerable<Integer>] A collection of direct message IDs.
      # @overload direct_messages(*ids, options)
      #   Returns direct messages
      #
      #   @see https://dev.twitter.com/rest/reference/get/direct_messages/show
      #   @param ids [Enumerable<Integer>] A collection of direct message IDs.
      #   @param options [Hash] A customizable set of options.
      def direct_messages(*args)
        arguments = Twitter::Arguments.new(args)
        if arguments.empty?
          direct_messages_received(arguments.options)
        else
          pmap(arguments) do |id|
            direct_message(id, arguments.options)
          end
        end
      end

      # Destroys direct messages
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/delete-message-event
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [nil] Response body from Twitter is nil if successful
      # @overload destroy_direct_message(*ids)
      #   @param ids [Enumerable<Integer>] A collection of direct message IDs.
      def destroy_direct_message(*ids)
        pmap(ids) do |id|
          perform_requests(:delete, '/1.1/direct_messages/events/destroy.json', id: id)
        end
        nil
      end

      # Sends a new direct message to the specified user from the authenticating user
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/new-event
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::DirectMessage] The sent message.
      # @param user [Integer, String, Twitter::User] A Twitter user ID
      # @param text [String] The text of your direct message, up to 10,000 characters.
      # @param options [Hash] A customizable set of options.
      def create_direct_message(user_id, text, options = {})
        event = perform_request_with_object(:json_post, '/1.1/direct_messages/events/new.json', format_json_options(user_id, text, options), Twitter::DirectMessageEvent)
        event.direct_message
      end
      alias d create_direct_message
      alias m create_direct_message
      alias dm create_direct_message

      # Create a new direct message event to the specified user from the authenticating user
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/new-event
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::DirectMessageEvent] The created direct message event.
      # @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @param text [String] The text of your direct message, up to 10,000 characters.
      # @param options [Hash] A customizable set of options.
      def create_direct_message_event(*args)
        arguments = Twitter::Arguments.new(args)
        options = arguments.options.dup
        options[:event] = {type: 'message_create', message_create: {target: {recipient_id: extract_id(arguments[0])}, message_data: {text: arguments[1]}}} if arguments.length >= 2
        response = Twitter::REST::Request.new(self, :json_post, '/1.1/direct_messages/events/new.json', options).perform
        Twitter::DirectMessageEvent.new(response[:event])
      end

      # Create a new direct message event to the specified user from the authenticating user with media
      #
      # @see https://developer.twitter.com/en/docs/direct-messages/sending-and-receiving/api-reference/new-event
      # @see https://developer.twitter.com/en/docs/direct-messages/message-attachments/guides/attaching-media
      # @note This method requires an access token with RWD (read, write & direct message) permissions. Consult The Application Permission Model for more information.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::DirectMessageEvent] The created direct message event.
      # @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @param text [String] The text of your direct message, up to 10,000 characters.
      # @param media [File] A media file (PNG, JPEG, GIF or MP4).
      # @param options [Hash] A customizable set of options.
      def create_direct_message_event_with_media(user, text, media, options = {})
        media_id = upload(media, media_category_prefix: 'dm')[:media_id]
        options = options.dup
        options[:event] = {type: 'message_create', message_create: {target: {recipient_id: extract_id(user)}, message_data: {text: text, attachment: {type: 'media', media: {id: media_id}}}}}
        response = Twitter::REST::Request.new(self, :json_post, '/1.1/direct_messages/events/new.json', options).perform
        Twitter::DirectMessageEvent.new(response[:event])
      end

    private

      def format_json_options(user_id, text, options)
        {'event': {'type': 'message_create', 'message_create': {'target': {'recipient_id': user_id}, 'message_data': {'text': text}.merge(options)}}}
      end
    end
  end
end
