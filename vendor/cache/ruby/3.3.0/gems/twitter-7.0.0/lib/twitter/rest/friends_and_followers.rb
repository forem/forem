require 'twitter/arguments'
require 'twitter/cursor'
require 'twitter/relationship'
require 'twitter/rest/request'
require 'twitter/rest/utils'
require 'twitter/user'
require 'twitter/utils'

module Twitter
  module REST
    module FriendsAndFollowers
      include Twitter::REST::Utils
      include Twitter::Utils

      # @see https://dev.twitter.com/rest/reference/get/friends/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload friend_ids(options = {})
      #   Returns an array of numeric IDs for every user the authenticated user is following
      #
      #   @param options [Hash] A customizable set of options.
      # @overload friend_ids(user, options = {})
      #   Returns an array of numeric IDs for every user the specified user is following
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def friend_ids(*args)
        cursor_from_response_with_user(:ids, nil, '/1.1/friends/ids.json', args)
      end

      # @see https://dev.twitter.com/rest/reference/get/followers/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload follower_ids(options = {})
      #   Returns an array of numeric IDs for every user following the authenticated user
      #
      #   @param options [Hash] A customizable set of options.
      # @overload follower_ids(user, options = {})
      #   Returns an array of numeric IDs for every user following the specified user
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def follower_ids(*args)
        cursor_from_response_with_user(:ids, nil, '/1.1/followers/ids.json', args)
      end

      # Returns the relationship of the authenticating user to the comma separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
      #
      # @see https://dev.twitter.com/rest/reference/get/friendships/lookup
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The requested users.
      # @overload friendships(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload friendships(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def friendships(*args)
        arguments = Twitter::Arguments.new(args)
        merge_users!(arguments.options, arguments)
        perform_get_with_objects('/1.1/friendships/lookup.json', arguments.options, Twitter::User)
      end

      # Returns an array of numeric IDs for every user who has a pending request to follow the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/get/friendships/incoming
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @param options [Hash] A customizable set of options.
      def friendships_incoming(options = {})
        perform_get_with_cursor('/1.1/friendships/incoming.json', options, :ids)
      end

      # Returns an array of numeric IDs for every protected user for whom the authenticating user has a pending follow request
      #
      # @see https://dev.twitter.com/rest/reference/get/friendships/outgoing
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @param options [Hash] A customizable set of options.
      def friendships_outgoing(options = {})
        perform_get_with_cursor('/1.1/friendships/outgoing.json', options, :ids)
      end

      # Allows the authenticating user to follow the specified users, unless they are already followed
      #
      # @see https://dev.twitter.com/rest/reference/post/friendships/create
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The followed users.
      # @overload follow(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload follow(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean] :follow (false) Enable notifications for the target user.
      def follow(*args)
        arguments = Twitter::Arguments.new(args)
        existing_friends = Thread.new do
          friend_ids.to_a
        end
        new_friends = Thread.new do
          users(args).collect(&:id)
        end
        follow!(new_friends.value - existing_friends.value, arguments.options)
      end
      alias create_friendship follow

      # Allows the authenticating user to follow the specified users
      #
      # @see https://dev.twitter.com/rest/reference/post/friendships/create
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The followed users.
      # @overload follow!(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload follow!(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean] :follow (false) Enable notifications for the target user.
      def follow!(*args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |user|
          perform_post_with_object('/1.1/friendships/create.json', merge_user(arguments.options, user), Twitter::User)
        end.compact
      end
      alias create_friendship! follow!

      # Allows the authenticating user to unfollow the specified users
      #
      # @see https://dev.twitter.com/rest/reference/post/friendships/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::User>] The unfollowed users.
      # @overload unfollow(*users)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      # @overload unfollow(*users, options)
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def unfollow(*args)
        parallel_users_from_response(:post, '/1.1/friendships/destroy.json', args)
      end
      alias destroy_friendship unfollow

      # Allows one to enable or disable retweets and device notifications from the specified user.
      #
      # @see https://dev.twitter.com/rest/reference/post/friendships/update
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Relationship]
      # @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @param options [Hash] A customizable set of options.
      # @option options [Boolean] :device Enable/disable device notifications from the target user.
      # @option options [Boolean] :retweets Enable/disable retweets from the target user.
      def friendship_update(user, options = {})
        merge_user!(options, user)
        perform_post_with_object('/1.1/friendships/update.json', options, Twitter::Relationship)
      end

      # Returns detailed information about the relationship between two users
      #
      # @see https://dev.twitter.com/rest/reference/get/friendships/show
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Relationship]
      # @param source [Integer, String, Twitter::User] The Twitter user ID, screen name, or object of the source user.
      # @param target [Integer, String, Twitter::User] The Twitter user ID, screen name, or object of the target user.
      # @param options [Hash] A customizable set of options.
      def friendship(source, target, options = {})
        options = options.dup
        merge_user!(options, source, 'source')
        options[:source_id] = options.delete(:source_user_id) unless options[:source_user_id].nil?
        merge_user!(options, target, 'target')
        options[:target_id] = options.delete(:target_user_id) unless options[:target_user_id].nil?
        perform_get_with_object('/1.1/friendships/show.json', options, Twitter::Relationship)
      end
      alias friendship_show friendship
      alias relationship friendship

      # Test for the existence of friendship between two users
      #
      # @see https://dev.twitter.com/rest/reference/get/friendships/show
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Boolean] true if user_a follows user_b, otherwise false.
      # @param source [Integer, String, Twitter::User] The Twitter user ID, screen name, or object of the source user.
      # @param target [Integer, String, Twitter::User] The Twitter user ID, screen name, or object of the target user.
      # @param options [Hash] A customizable set of options.
      def friendship?(source, target, options = {})
        friendship(source, target, options).source.following?
      end

      # Returns a cursored collection of user objects for users following the specified user.
      #
      # @see https://dev.twitter.com/rest/reference/get/followers/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload followers(options = {})
      #   Returns a cursored collection of user objects for users following the authenticated user.
      #
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      #   @option options [Boolean, String, Integer] :include_user_entities The user entities node will be disincluded when set to false.
      # @overload followers(user, options = {})
      #   Returns a cursored collection of user objects for users following the specified user.
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      #   @option options [Boolean, String, Integer] :include_user_entities The user entities node will be disincluded when set to false.
      def followers(*args)
        cursor_from_response_with_user(:users, Twitter::User, '/1.1/followers/list.json', args)
      end

      # Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").
      #
      # @see https://dev.twitter.com/rest/reference/get/friends/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload friends(options = {})
      #   Returns a cursored collection of user objects for every user the authenticated user is following (otherwise known as their "friends").
      #
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      #   @option options [Boolean, String, Integer] :include_user_entities The user entities node will be disincluded when set to false.
      # @overload friends(user, options = {})
      #   Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :skip_status Do not include contributee's Tweets when set to true, 't' or 1.
      #   @option options [Boolean, String, Integer] :include_user_entities The user entities node will be disincluded when set to false.
      def friends(*args)
        cursor_from_response_with_user(:users, Twitter::User, '/1.1/friends/list.json', args)
      end
      alias following friends

      # Returns a collection of user IDs that the currently authenticated user does not want to receive retweets from.
      # @see https://dev.twitter.com/rest/reference/get/friendships/no_retweets/ids
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Integer>]
      # @param options [Hash] A customizable set of options.
      def no_retweet_ids(options = {})
        perform_get('/1.1/friendships/no_retweets/ids.json', options).collect(&:to_i)
      end
      alias no_retweets_ids no_retweet_ids
    end
  end
end
