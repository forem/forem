require 'twitter/arguments'
require 'twitter/error'
require 'twitter/rest/utils'
require 'twitter/tweet'
require 'twitter/user'
require 'twitter/utils'

module Twitter
  module REST
    module Favorites
      include Twitter::REST::Utils
      include Twitter::Utils

      # @see https://dev.twitter.com/rest/reference/get/favorites/list
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] favorite Tweets.
      # @overload favorites(options = {})
      #   Returns the 20 most recent favorite Tweets for the authenticating user
      #
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count Specifies the number of records to retrieve. Must be less than or equal to 200.
      #   @option options [Integer] :since_id Returns results with an ID greater than (that is, more recent than) the specified ID.
      # @overload favorites(user, options = {})
      #   Returns the 20 most recent favorite Tweets for the specified user
      #
      #   @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Integer] :count Specifies the number of records to retrieve. Must be less than or equal to 200.
      #   @option options [Integer] :since_id Returns results with an ID greater than (that is, more recent than) the specified ID.
      def favorites(*args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop) if arguments.last
        perform_get_with_objects('/1.1/favorites/list.json', arguments.options, Twitter::Tweet)
      end

      # Un-favorites the specified Tweets as the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/favorites/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] The un-favorited Tweets.
      # @overload unfavorite(*tweets)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      # @overload unfavorite(*tweets, options)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      #   @param options [Hash] A customizable set of options.
      def unfavorite(*args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |tweet|
          begin
            perform_post_with_object('/1.1/favorites/destroy.json', arguments.options.merge(id: extract_id(tweet)), Twitter::Tweet)
          rescue Twitter::Error::NotFound
            next
          end
        end.compact
      end
      alias destroy_favorite unfavorite

      # Un-favorites the specified Tweets as the authenticating user and raises an error if one is not found
      #
      # @see https://dev.twitter.com/rest/reference/post/favorites/destroy
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::NotFound] Error raised when tweet does not exist or has been deleted.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] The un-favorited Tweets.
      # @overload unfavorite!(*tweets)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      # @overload unfavorite!(*tweets, options)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      #   @param options [Hash] A customizable set of options.
      def unfavorite!(*args)
        parallel_objects_from_response(Twitter::Tweet, :post, '/1.1/favorites/destroy.json', args)
      end

      # Favorites the specified Tweets as the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/favorites/create
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] The favorited Tweets.
      # @overload favorite(*tweets)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      # @overload favorite(*tweets, options)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      #   @param options [Hash] A customizable set of options.
      def favorite(*args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |tweet|
          begin
            perform_post_with_object('/1.1/favorites/create.json', arguments.options.merge(id: extract_id(tweet)), Twitter::Tweet)
          rescue Twitter::Error::AlreadyFavorited, Twitter::Error::NotFound
            next
          end
        end.compact
      end
      alias fav favorite
      alias fave favorite

      # Favorites the specified Tweets as the authenticating user and raises an error if one has already been favorited
      #
      # @see https://dev.twitter.com/rest/reference/post/favorites/create
      # @rate_limited No
      # @authentication Requires user context
      # @raise [Twitter::Error::AlreadyFavorited] Error raised when tweet has already been favorited.
      # @raise [Twitter::Error::NotFound] Error raised when tweet does not exist or has been deleted.
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] The favorited Tweets.
      # @overload favorite!(*tweets)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      # @overload favorite!(*tweets, options)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      #   @param options [Hash] A customizable set of options.
      def favorite!(*args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |tweet|
          perform_post_with_object('/1.1/favorites/create.json', arguments.options.merge(id: extract_id(tweet)), Twitter::Tweet)
        end
      end
      alias create_favorite! favorite!
      alias fav! favorite!
      alias fave! favorite!
    end
  end
end
