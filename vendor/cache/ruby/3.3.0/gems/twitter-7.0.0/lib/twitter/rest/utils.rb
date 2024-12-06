require 'addressable/uri'
require 'twitter/arguments'
require 'twitter/cursor'
require 'twitter/rest/request'
require 'twitter/user'
require 'twitter/utils'
require 'uri'

module Twitter
  module REST
    module Utils
      include Twitter::Utils
      DEFAULT_CURSOR = -1

    private

      # Take a URI string or Twitter::Identity object and return its ID
      #
      # @param object [Integer, String, URI, Twitter::Identity] An ID, URI, or object.
      # @return [Integer]
      def extract_id(object)
        case object
        when ::Integer
          object
        when ::String
          object.split('/').last.to_i
        when URI, Addressable::URI
          object.path.split('/').last.to_i
        when Twitter::Identity
          object.id
        end
      end

      # @param path [String]
      # @param options [Hash]
      def perform_get(path, options = {})
        perform_request(:get, path, options)
      end

      # @param path [String]
      # @param options [Hash]
      def perform_post(path, options = {})
        perform_request(:post, path, options)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param options [Hash]
      def perform_request(request_method, path, options = {}, params = nil)
        Twitter::REST::Request.new(self, request_method, path, options, params).perform
      end

      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_get_with_object(path, options, klass)
        perform_request_with_object(:get, path, options, klass)
      end

      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_post_with_object(path, options, klass)
        perform_request_with_object(:post, path, options, klass)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_request_with_object(request_method, path, options, klass, params = nil)
        response = perform_request(request_method, path, options, params)
        klass.new(response)
      end

      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_get_with_objects(path, options, klass)
        perform_request_with_objects(:get, path, options, klass)
      end

      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_post_with_objects(path, options, klass)
        perform_request_with_objects(:post, path, options, klass)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param options [Hash]
      # @param klass [Class]
      def perform_request_with_objects(request_method, path, options, klass)
        perform_request(request_method, path, options).collect do |element|
          klass.new(element)
        end
      end

      # @param path [String]
      # @param options [Hash]
      # @param collection_name [Symbol]
      # @param klass [Class]
      def perform_get_with_cursor(path, options, collection_name, klass = nil)
        limit = options.delete(:limit)
        if options[:no_default_cursor]
          options.delete(:no_default_cursor)
        else
          merge_default_cursor!(options)
        end

        request = Twitter::REST::Request.new(self, :get, path, options)
        Twitter::Cursor.new(collection_name.to_sym, klass, request, limit)
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Twitter::User>]
      def parallel_users_from_response(request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |user|
          perform_request_with_object(request_method, path, merge_user(arguments.options, user), Twitter::User)
        end
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array<Twitter::User>]
      def users_from_response(request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop || user_id) unless arguments.options[:user_id] || arguments.options[:screen_name]
        perform_request_with_objects(request_method, path, arguments.options, Twitter::User)
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array]
      def objects_from_response_with_user(klass, request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop)
        perform_request_with_objects(request_method, path, arguments.options, klass)
      end

      # @param klass [Class]
      # @param request_method [Symbol]
      # @param path [String]
      # @param args [Array]
      # @return [Array]
      def parallel_objects_from_response(klass, request_method, path, args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |object|
          perform_request_with_object(request_method, path, arguments.options.merge(id: extract_id(object)), klass)
        end
      end

      # @param request_method [Symbol]
      # @param path [String]
      # @param ids [Array]
      # @return nil
      def perform_requests(request_method, path, ids)
        ids.each do |id|
          perform_request(request_method, path, id: id)
        end
        nil
      end

      # @param collection_name [Symbol]
      # @param klass [Class]
      # @param path [String]
      # @param args [Array]
      # @return [Twitter::Cursor]
      def cursor_from_response_with_user(collection_name, klass, path, args)
        arguments = Twitter::Arguments.new(args)
        merge_user!(arguments.options, arguments.pop || user_id) unless arguments.options[:user_id] || arguments.options[:screen_name]
        perform_get_with_cursor(path, arguments.options, collection_name, klass)
      end

      def user_id
        @user_id ||= verify_credentials(skip_status: true).id
      end

      def user_id?
        instance_variable_defined?(:@user_id)
      end

      def merge_default_cursor!(options)
        options[:cursor] = DEFAULT_CURSOR unless options[:cursor]
      end

      # Take a user and merge it into the hash with the correct key
      #
      # @param hash [Hash]
      # @param user [Integer, String, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @return [Hash]
      def merge_user(hash, user, prefix = nil)
        merge_user!(hash.dup, user, prefix)
      end

      # Take a user and merge it into the hash with the correct key
      #
      # @param hash [Hash]
      # @param user [Integer, String, URI, Twitter::User] A Twitter user ID, screen name, URI, or object.
      # @return [Hash]
      def merge_user!(hash, user, prefix = nil)
        case user
        when Integer
          set_compound_key('user_id', user, hash, prefix)
        when String
          set_compound_key('screen_name', user, hash, prefix)
        when URI, Addressable::URI
          set_compound_key('screen_name', user.path.split('/').last, hash, prefix)
        when Twitter::User
          set_compound_key('user_id', user.id, hash, prefix)
        end
      end

      def set_compound_key(key, value, hash, prefix = nil)
        compound_key = [prefix, key].compact.join('_').to_sym
        hash[compound_key] = value
        hash
      end

      # Take a multiple users and merge them into the hash with the correct keys
      #
      # @param hash [Hash]
      # @param users [Enumerable<Integer, String, Twitter::User>] A collection of Twitter user IDs, screen_names, or objects.
      # @return [Hash]
      def merge_users(hash, users)
        copy = hash.dup
        merge_users!(copy, users)
        copy
      end

      # Take a multiple users and merge them into the hash with the correct keys
      #
      # @param hash [Hash]
      # @param users [Enumerable<Integer, String, URI, Twitter::User>] A collection of Twitter user IDs, screen_names, URIs, or objects.
      # @return [Hash]
      def merge_users!(hash, users)
        user_ids, screen_names = collect_users(users)
        hash[:user_id] = user_ids.join(',') unless user_ids.empty?
        hash[:screen_name] = screen_names.join(',') unless screen_names.empty?
      end

      def collect_users(users) # rubocop:disable Metrics/MethodLength
        user_ids = []
        screen_names = []
        users.each do |user|
          case user
          when Integer               then user_ids << user
          when Twitter::User         then user_ids << user.id
          when String                then screen_names << user
          when URI, Addressable::URI then screen_names << user.path.split('/').last
          end
        end
        [user_ids, screen_names]
      end
    end
  end
end
