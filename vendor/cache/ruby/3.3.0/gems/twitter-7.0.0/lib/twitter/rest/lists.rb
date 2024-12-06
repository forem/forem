require 'addressable/uri'
require 'twitter/arguments'
require 'twitter/cursor'
require 'twitter/error'
require 'twitter/list'
require 'twitter/rest/request'
require 'twitter/rest/utils'
require 'twitter/tweet'
require 'twitter/user'
require 'twitter/utils'
require 'uri'

module Twitter
  module REST
    module Lists
      include Twitter::REST::Utils
      include Twitter::Utils
      MAX_USERS_PER_REQUEST = 100

      # Returns all lists the authenticating or specified user subscribes to, including their own
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::List>]
      # @overload lists(options = {})
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean] :reverse Set this to true if you would like owned lists to be returned first.
      # @overload lists(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean] :reverse Set this to true if you would like owned lists to be returned first.
      def lists(*args)
        objects_from_response_with_user(Twitter::List, :get, '/1.1/lists/list.json', args)
      end
      alias lists_subscribed_to lists

      # Show tweet timeline for members of the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/statuses
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>]
      # @overload list_timeline(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :since_id Returns results with an ID greater than (that is, more recent than) the specified ID.
      #   @option options [Integer] :max_id Returns results with an ID less than (that is, older than) or equal to the specified ID.
      #   @option options [Integer] :count The number of results to retrieve.
      # @overload list_timeline(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :since_id Returns results with an ID greater than (that is, more recent than) the specified ID.
      #   @option options [Integer] :max_id Returns results with an ID less than (that is, older than) or equal to the specified ID.
      #   @option options [Integer] :count The number of results to retrieve.
      def list_timeline(*args)
        arguments = Twitter::Arguments.new(args)
        merge_list!(arguments.options, arguments.pop)
        merge_owner!(arguments.options, arguments.pop)
        perform_get_with_objects('/1.1/lists/statuses.json', arguments.options, Twitter::Tweet)
      end

      # Removes the specified member from the list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/members/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The list.
      # @overload remove_list_member(list, user_to_remove, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_remove [Integer, String] The user id or screen name of the list member to remove.
      #   @param options [Hash] A customizable set of options.
      # @overload remove_list_member(user, list, user_to_remove, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_remove [Integer, String] The user id or screen name of the list member to remove.
      #   @param options [Hash] A customizable set of options.
      def remove_list_member(*args)
        list_from_response_with_user('/1.1/lists/members/destroy.json', args)
      end

      # List the lists the specified user has been added to
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/memberships
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload memberships(options = {})
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count The amount of results to return per page. Defaults to 20. No more than 1000 results will ever be returned in a single page.
      #   @option options [Boolean, String, Integer] :filter_to_owned_lists When set to true, t or 1, will return just lists the authenticating user owns, and the user represented by user_id or screen_name is a member of.
      # @overload memberships(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count The amount of results to return per page. Defaults to 20. No more than 1000 results will ever be returned in a single page.
      #   @option options [Boolean, String, Integer] :filter_to_owned_lists When set to true, t or 1, will return just lists the authenticating user owns, and the user represented by user_id or screen_name is a member of.
      def memberships(*args)
        cursor_from_response_with_user(:lists, Twitter::List, '/1.1/lists/memberships.json', args)
      end

      # Returns the subscribers of the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/subscribers
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor] The subscribers of the specified list.
      # @overload list_subscribers(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list_subscribers(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def list_subscribers(*args)
        cursor_from_response_with_list('/1.1/lists/subscribers.json', args)
      end

      # Make the authenticated user follow the specified list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/subscribers/create
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The specified list.
      # @overload list_subscribe(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list_subscribe(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def list_subscribe(*args)
        list_from_response(:post, '/1.1/lists/subscribers/create.json', args)
      end

      # Check if a user is a subscriber of the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/subscribers/show
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Boolean] true if user is a subscriber of the specified list, otherwise false.
      # @overload list_subscriber?(list, user_to_check, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_check [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list_subscriber?(user, list, user_to_check, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_check [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @return [Boolean] true if user is a subscriber of the specified list, otherwise false.
      def list_subscriber?(*args)
        list_user?(:get, '/1.1/lists/subscribers/show.json', args)
      end

      # Unsubscribes the authenticated user form the specified list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/subscribers/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The specified list.
      # @overload list_unsubscribe(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list_unsubscribe(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def list_unsubscribe(*args)
        list_from_response(:post, '/1.1/lists/subscribers/destroy.json', args)
      end

      # Adds specified members to a list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/members/create_all
      # @note Lists are limited to having 5,000 members, and you are limited to adding up to 100 members to a list at a time with this method.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Forbidden] Error raised when user has already been added.
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The list.
      # @overload add_list_members(list, users, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      # @overload add_list_members(user, list, users, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def add_list_members(*args)
        list_from_response_with_users('/1.1/lists/members/create_all.json', args)
      end

      # Check if a user is a member of the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/members/show
      # @authentication Requires user context
      # @rate_limited Yes
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Boolean] true if user is a member of the specified list, otherwise false.
      # @overload list_member?(list, user_to_check, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_check [Integer, String] The user ID or screen name of the list member.
      #   @param options [Hash] A customizable set of options.
      # @overload list_member?(user, list, user_to_check, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_check [Integer, String] The user ID or screen name of the list member.
      #   @param options [Hash] A customizable set of options.
      def list_member?(*args)
        list_user?(:get, '/1.1/lists/members/show.json', args)
      end

      # Returns the members of the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/members
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload list_members(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list_members(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def list_members(*args)
        cursor_from_response_with_list('/1.1/lists/members.json', args)
      end

      # Add a member to a list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/members/create
      # @note Lists are limited to having 5,000 members.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The list.
      # @overload add_list_member(list, user_to_add, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_add [Integer, String] The user id or screen name to add to the list.
      #   @param options [Hash] A customizable set of options.
      # @overload add_list_member(user, list, user_to_add, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param user_to_add [Integer, String] The user id or screen name to add to the list.
      #   @param options [Hash] A customizable set of options.
      def add_list_member(*args)
        list_from_response_with_user('/1.1/lists/members/create.json', args)
      end

      # Deletes the specified list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/destroy
      # @note Must be owned by the authenticated user.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The deleted list.
      # @overload destroy_list(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload destroy_list(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def destroy_list(*args)
        list_from_response(:post, '/1.1/lists/destroy.json', args)
      end

      # Updates the specified list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/update
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The created list.
      # @overload list_update(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [String] :mode ('public') Whether your list is public or private. Values can be 'public' or 'private'.
      #   @option options [String] :description The description to give the list.
      # @overload list_update(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [String] :mode ('public') Whether your list is public or private. Values can be 'public' or 'private'.
      #   @option options [String] :description The description to give the list.
      def list_update(*args)
        list_from_response(:post, '/1.1/lists/update.json', args)
      end

      # Creates a new list for the authenticated user
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/create
      # @note Accounts are limited to 20 lists.
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The created list.
      # @param name [String] The name for the list.
      # @param options [Hash] A customizable set of options.
      # @option options [String] :mode ('public') Whether your list is public or private. Values can be 'public' or 'private'.
      # @option options [String] :description The description to give the list.
      def create_list(name, options = {})
        perform_post_with_object('/1.1/lists/create.json', options.merge(name: name), Twitter::List)
      end

      # Show the specified list
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/show
      # @note Private lists will only be shown if the authenticated user owns the specified list.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The specified list.
      # @overload list(list, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      # @overload list(user, list, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def list(*args)
        list_from_response(:get, '/1.1/lists/show.json', args)
      end

      # List the lists the specified user follows
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/subscriptions
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::Cursor]
      # @overload subscriptions(options = {})
      #   @param options [Hash] A customizable set of options.
      # @overload subscriptions(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      def subscriptions(*args)
        cursor_from_response_with_user(:lists, Twitter::List, '/1.1/lists/subscriptions.json', args)
      end

      # Removes specified members from the list
      #
      # @see https://dev.twitter.com/rest/reference/post/lists/members/destroy_all
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when supplied list is not found.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Twitter::List] The list.
      # @overload remove_list_members(list, users, options = {})
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      # @overload remove_list_members(user, list, users, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param list [Integer, String, Twitter::List] A Twitter list ID, slug, URI, or object.
      #   @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen names, or objects.
      #   @param options [Hash] A customizable set of options.
      def remove_list_members(*args)
        list_from_response_with_users('/1.1/lists/members/destroy_all.json', args)
      end

      # Returns the lists owned by the specified Twitter user
      #
      # @see https://dev.twitter.com/rest/reference/get/lists/ownerships
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::List>]
      # @overload owned_lists(options = {})
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count The amount of results to return per page. Defaults to 20. No more than 1000 results will ever be returned in a single page.
      # @overload owned_lists(user, options = {})
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count The amount of results to return per page. Defaults to 20. No more than 1000 results will ever be returned in a single page.
      def owned_lists(*args)
        cursor_from_response_with_user(:lists, Twitter::List, '/1.1/lists/ownerships.json', args)
      end

    private

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Twitter::User>]
      def list_from_response(request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        merge_list!(arguments.options, arguments.pop)
        merge_owner!(arguments.options, arguments.pop)
        perform_request_with_object(request_method, path, arguments.options, Twitter::List)
      end

      def cursor_from_response_with_list(path, args)
        arguments = Twitter::Arguments.new(args)
        merge_list!(arguments.options, arguments.pop)
        merge_owner!(arguments.options, arguments.pop)
        perform_get_with_cursor(path, arguments.options, :users, Twitter::User)
      end

      def list_user?(request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop)
        merge_list!(arguments.options, arguments.pop)
        merge_owner!(arguments.options, arguments.pop)
        perform_request(request_method.to_sym, path, arguments.options)
        true
      rescue Twitter::Error::Forbidden, Twitter::Error::NotFound
        false
      end

      def list_from_response_with_user(path, args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop)
        merge_list!(arguments.options, arguments.pop)
        merge_owner!(arguments.options, arguments.pop)
        perform_post_with_object(path, arguments.options, Twitter::List)
      end

      def list_from_response_with_users(path, args)
        arguments = args.dup
        options = arguments.last.is_a?(::Hash) ? arguments.pop : {}
        members = arguments.pop
        merge_list!(options, arguments.pop)
        merge_owner!(options, arguments.pop)
        pmap(members.each_slice(MAX_USERS_PER_REQUEST)) do |users|
          perform_post_with_object(path, merge_users(options, users), Twitter::List)
        end.last
      end

      # Take a list and merge it into the hash with the correct key
      #
      # @param hash [Hash]
      # @param list [Integer, String, URI, Twitter::List] A Twitter list ID, slug, URI, or object.
      def merge_list!(hash, list)
        case list
        when Integer               then hash[:list_id] = list
        when Twitter::List         then merge_list_and_owner!(hash, list)
        when String                then merge_slug_and_owner!(hash, list)
        when URI, Addressable::URI then merge_slug_and_owner!(hash, list.path)
        end
      end

      def merge_slug_and_owner!(hash, path)
        list = path.split('/')
        hash[:slug] = list.pop
        hash[:owner_screen_name] = list.pop unless list.empty?
      end

      def merge_list_and_owner!(hash, list)
        merge_list!(hash, list.id)
        merge_owner!(hash, list.user)
      end

      # Take an owner and merge it into the hash with the correct key
      #
      # @param hash [Hash]
      # @param user[Integer, String, Twitter::User] A Twitter user ID, screen_name, or object.
      # @return [Hash]
      def merge_owner!(hash, user)
        return hash if hash[:owner_id] || hash[:owner_screen_name]

        if user
          merge_user!(hash, user, 'owner')
          hash[:owner_id] = hash.delete(:owner_user_id) unless hash[:owner_user_id].nil?
        else
          hash[:owner_id] = user_id
        end
        hash
      end
    end
  end
end
