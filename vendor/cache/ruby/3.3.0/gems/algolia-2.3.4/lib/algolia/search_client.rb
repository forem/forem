require 'faraday'
require 'openssl'
require 'base64'

module Algolia
  module Search
    # Class Client
    class Client
      include CallType
      include Helpers

      # Initialize a client to connect to Algolia
      #
      # @param search_config [Search::Config] a Search::Config object which contains your APP_ID and API_KEY
      # @option adapter [Object] adapter object used for the connection
      # @option logger [Object]
      # @option http_requester [Object] http_requester object used for the connection
      #
      def initialize(search_config, opts = {})
        @config      = search_config
        adapter      = opts[:adapter] || Defaults::ADAPTER
        @logger      = opts[:logger] || LoggerHelper.create
        requester    = opts[:http_requester] || Defaults::REQUESTER_CLASS.new(adapter, @logger)
        @transporter = Transport::Transport.new(@config, requester)
      end

      # Create a new client providing only app ID and API key
      #
      # @param app_id [String] Algolia application ID
      # @param api_key [String] Algolia API key
      #
      # @return self
      #
      def self.create(app_id, api_key)
        config = Search::Config.new(application_id: app_id, api_key: api_key)
        create_with_config(config)
      end

      # Create a new client providing only the search config
      #
      # @param config [Search::Config]
      #
      # @return self
      #
      def self.create_with_config(config)
        new(config)
      end

      # Fetch the task status until it returns as "published", meaning the operation is done
      #
      # @param index_name [String]
      # @param task_id [Integer]
      # @param time_before_retry [Integer] time before retrying the call, in ms
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return nil
      #
      def wait_task(index_name, task_id, time_before_retry = WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY, opts = {})
        loop do
          status = get_task_status(index_name, task_id, opts)
          if status == 'published'
            return
          end
          sleep(time_before_retry.to_f / 1000)
        end
      end

      # Check the status of a task on the server.
      # All server task are asynchronous and you can check the status of a task with this method.
      #
      # @param index_name [String] index used for the calls
      # @param task_id [Integer] the id of the task returned by server
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [String]
      #
      def get_task_status(index_name, task_id, opts = {})
        res = @transporter.read(:GET, path_encode('/1/indexes/%s/task/%s', index_name, task_id), {}, opts)
        get_option(res, 'status')
      end

      # # # # # # # # # # # # # # # # # # # # #
      # INDEX METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Initialize an index with a given name
      #
      # @param index_name [String] name of the index to init
      #
      # @return [Index] new Index instance
      #
      def init_index(index_name)
        stripped_index_name = index_name.strip
        if stripped_index_name.empty?
          raise AlgoliaError, 'Please provide a valid index name'
        end
        Index.new(stripped_index_name, @transporter, @config, @logger)
      end

      # List all indexes of the client
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def list_indexes(opts = {})
        @transporter.read(:GET, '/1/indexes', {}, opts)
      end

      # Retrieve the client logs
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_logs(opts = {})
        @transporter.read(:GET, '/1/logs', {}, opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # COPY OPERATIONS
      # # # # # # # # # # # # # # # # # # # # #

      # Copy the rules from source index to destination index
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_rules(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['rules']
        copy_index(src_index_name, dest_index_name, request_options)
      end

      # Copy the rules from source index to destination index and wait for the task to complete
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_rules!(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['rules']
        copy_index!(src_index_name, dest_index_name, request_options)
      end

      # Copy the settings from source index to destination index
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_settings(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['settings']
        copy_index(src_index_name, dest_index_name, request_options)
      end

      # Copy the settings from source index to destination index and wait for the task to complete
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_settings!(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['settings']
        copy_index!(src_index_name, dest_index_name, request_options)
      end

      # Copy the synonyms from source index to destination index
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_synonyms(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['synonyms']
        copy_index(src_index_name, dest_index_name, request_options)
      end

      # Copy the synonyms from source index to destination index and wait for the task to complete
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_synonyms!(src_index_name, dest_index_name, opts = {})
        request_options         = symbolize_hash(opts)
        request_options[:scope] = ['synonyms']
        copy_index!(src_index_name, dest_index_name, request_options)
      end

      # Copy the source index to the destination index
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_index(src_index_name, dest_index_name, opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/operation', src_index_name), { operation: 'copy', destination: dest_index_name }, opts)

        IndexingResponse.new(init_index(src_index_name), response)
      end

      # Copy the source index to the destination index and wait for the task to complete
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_index!(src_index_name, dest_index_name, opts = {})
        response     = copy_index(src_index_name, dest_index_name, opts)

        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # MOVE OPERATIONS
      # # # # # # # # # # # # # # # # # # # # #

      # Move the source index to the destination index
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def move_index(src_index_name, dest_index_name, opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/operation', src_index_name), { operation: 'move', destination: dest_index_name }, opts)

        IndexingResponse.new(init_index(src_index_name), response)
      end

      # Move the source index to the destination index and wait for the task to complete
      #
      # @param src_index_name [String] Name of the source index
      # @param dest_index_name [String] Name of the destination index
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def move_index!(src_index_name, dest_index_name, opts = {})
        response = move_index(src_index_name, dest_index_name, opts)

        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # API KEY METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Get the designated API key
      #
      # @param key_id [String] API key to retrieve
      #
      # @return [Hash]
      #
      def get_api_key(key_id, opts = {})
        @transporter.read(:GET, path_encode('/1/keys/%s', key_id), {}, opts)
      end

      # Add an API key with the given ACL
      #
      # @param acl [Array] API key to retrieve
      # @param opts [Hash] contains extra parameters to send with your query used for the key
      #
      # @return [AddApiKeyResponse]
      #
      def add_api_key(acl, opts = {})
        response = @transporter.write(:POST, '/1/keys', { acl: acl }, opts)

        AddApiKeyResponse.new(self, response)
      end

      # Add an API key with the given ACL and wait for the task to complete
      #
      # @param acl [Array] API key to retrieve
      # @param opts [Hash] contains extra parameters to send with your query used for the key
      #
      # @return [AddApiKeyResponse]
      #
      def add_api_key!(acl, opts = {})
        response = add_api_key(acl, opts)

        response.wait(opts)
      end

      # Update an API key with the optional parameters
      #
      # @param key [String] API key to update
      # @param opts [Hash] contains extra parameters to send with your query used to update the key
      #
      # @return [UpdateApiKeyResponse]
      #
      def update_api_key(key, opts = {})
        request_options = symbolize_hash(opts)

        response = @transporter.write(:PUT, path_encode('/1/keys/%s', key), {}, request_options)

        UpdateApiKeyResponse.new(self, response, request_options)
      end

      # Update an API key with the optional parameters and wait for the task to complete
      #
      # @param key [String] API key to update
      # @param opts [Hash] contains extra parameters to send with your query used to update the key
      #
      # @return [UpdateApiKeyResponse]
      #
      def update_api_key!(key, opts = {})
        response = update_api_key(key, opts)

        response.wait(opts)
      end

      # Delete the given API key
      #
      # @param key [String] API key to delete
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [DeleteApiKeyResponse]
      #
      def delete_api_key(key, opts = {})
        response = @transporter.write(:DELETE, path_encode('/1/keys/%s', key), {}, opts)

        DeleteApiKeyResponse.new(self, response, key)
      end

      # Delete the given API key and wait for the task to complete
      #
      # @param key [String] API key to delete
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [DeleteApiKeyResponse]
      #
      def delete_api_key!(key, opts = {})
        response = delete_api_key(key, opts)

        response.wait(opts)
      end

      # Restore the given API key
      #
      # @param key [String] API key to restore
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [RestoreApiKeyResponse]
      #
      def restore_api_key(key, opts = {})
        @transporter.write(:POST, path_encode('/1/keys/%s/restore', key), {}, opts)

        RestoreApiKeyResponse.new(self, key)
      end

      # Restore the given API key and wait for the task to complete
      #
      # @param key [String] API key to restore
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [RestoreApiKeyResponse]
      #
      def restore_api_key!(key, opts = {})
        response = restore_api_key(key, opts)

        response.wait(opts)
      end

      # List all keys associated with the current client
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def list_api_keys(opts = {})
        @transporter.read(:GET, '/1/keys', {}, opts)
      end

      # Generate a secured API key from the given parent key with the given restrictions
      #
      # @param parent_key [String] Parent API key used the generate the secured key
      # @param restrictions [Hash] Restrictions to apply on the secured key
      #
      # @return [String]
      #
      def self.generate_secured_api_key(parent_key, restrictions)
        url_encoded_restrictions = to_query_string(symbolize_hash(restrictions))
        hmac                     = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), parent_key, url_encoded_restrictions)
        Base64.encode64("#{hmac}#{url_encoded_restrictions}").gsub("\n", '')
      end

      # Returns the time the given securedAPIKey remains valid in seconds
      #
      # @param secured_api_key [String]
      #
      # @return [Integer]
      #
      def self.get_secured_api_key_remaining_validity(secured_api_key)
        now         = Time.now.to_i
        decoded_key = Base64.decode64(secured_api_key)
        regex       = 'validUntil=(\d+)'
        matches     = decoded_key.match(regex)

        if matches.nil?
          raise AlgoliaError, 'The SecuredAPIKey doesn\'t have a validUntil parameter.'
        end

        valid_until = matches[1].to_i

        valid_until - now
      end

      # # # # # # # # # # # # # # # # # # # # #
      # MULTIPLE* METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Batch multiple operations
      #
      # @param operations [Array] array of operations (addObject, updateObject, ...)
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [MultipleIndexBatchIndexingResponse]
      #
      def multiple_batch(operations, opts = {})
        response = @transporter.write(:POST, '/1/indexes/*/batch', { requests: operations }, opts)

        MultipleIndexBatchIndexingResponse.new(self, response)
      end

      # Batch multiple operations and wait for the task to complete
      #
      # @param operations [Array] array of operations (addObject, updateObject, ...)
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [MultipleIndexBatchIndexingResponse]
      #
      def multiple_batch!(operations, opts = {})
        response = multiple_batch(operations, opts)

        response.wait(opts)
      end

      # Retrieve multiple objects in one batch request
      #
      # @param requests [Array] array of requests
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def multiple_get_objects(requests, opts = {})
        @transporter.read(:POST, '/1/indexes/*/objects', { requests: requests }, opts)
      end

      # Search multiple indices
      #
      # @param queries [Array] array of queries
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def multiple_queries(queries, opts = {})
        queries.each do |q|
          q[:params] = to_query_string(q[:params]) unless q[:params].nil? || q[:params].is_a?(String)
        end
        @transporter.read(:POST, '/1/indexes/*/queries', { requests: queries }, opts)
      end
      alias_method :search, :multiple_queries

      # # # # # # # # # # # # # # # # # # # # #
      # MCM METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Assign or Move a userID to a cluster.
      #
      # @param user_id [String]
      # @param cluster_name [String]
      #
      # @return [Hash]
      #
      def assign_user_id(user_id, cluster_name, opts = {})
        request_options           = symbolize_hash(opts)
        request_options[:headers] = { 'X-Algolia-User-ID': user_id }

        @transporter.write(:POST, '/1/clusters/mapping', { cluster: cluster_name }, request_options)
      end

      # Assign multiple userIDs to a cluster.
      #
      # @param user_ids [Array]
      # @param cluster_name [String]
      #
      # @return [Hash]
      #
      def assign_user_ids(user_ids, cluster_name, opts = {})
        @transporter.write(:POST, '/1/clusters/mapping/batch', { cluster: cluster_name, users: user_ids }, opts)
      end

      # Get the top 10 userIDs with the highest number of records per cluster.
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_top_user_ids(opts = {})
        @transporter.read(:GET, '/1/clusters/mapping/top', {}, opts)
      end

      # Returns the userID data stored in the mapping.
      #
      # @param user_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_user_id(user_id, opts = {})
        @transporter.read(:GET, path_encode('/1/clusters/mapping/%s', user_id), {}, opts)
      end

      # List the clusters available in a multi-clusters setup for a single appID
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def list_clusters(opts = {})
        @transporter.read(:GET, '/1/clusters', {}, opts)
      end

      # List the userIDs assigned to a multi-clusters appID
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def list_user_ids(opts = {})
        @transporter.read(:GET, '/1/clusters/mapping', {}, opts)
      end

      # Remove a userID and its associated data from the multi-clusters
      #
      # @param user_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def remove_user_id(user_id, opts = {})
        request_options           = symbolize_hash(opts)
        request_options[:headers] = { 'X-Algolia-User-ID': user_id }

        @transporter.write(:DELETE, '/1/clusters/mapping', {}, request_options)
      end

      # Search for userIDs
      #
      # @param query [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def search_user_ids(query, opts = {})
        @transporter.read(:POST, '/1/clusters/mapping/search', { query: query }, opts)
      end

      # Get the status of your clusters' migrations or user creations
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def pending_mappings?(opts = {})
        retrieve_mappings = false

        request_options = symbolize_hash(opts)
        if request_options.has_key?(:retrieveMappings)
          retrieve_mappings = request_options[:retrieveMappings]
          request_options.delete(:retrieveMappings)
        end

        @transporter.read(:GET, '/1/clusters/mapping/pending' + handle_params({ getClusters: retrieve_mappings }), {}, request_options)
      end

      # Aliases the pending_mappings? method
      #
      alias_method :has_pending_mappings, :pending_mappings?

      # # # # # # # # # # # # # # # # # # # # #
      # CUSTOM DICTIONARIES METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Save entries for a given dictionary
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param dictionary_entries [Array<Hash>] array of dictionary entries
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def save_dictionary_entries(dictionary, dictionary_entries, opts = {})
        response = @transporter.write(
          :POST,
          path_encode('/1/dictionaries/%s/batch', dictionary),
          { clearExistingDictionaryEntries: false, requests: chunk('addEntry', dictionary_entries) },
          opts
        )

        DictionaryResponse.new(self, response)
      end

      # Save entries for a given dictionary and wait for the task to finish
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param dictionary_entries [Array<Hash>] array of dictionary entries
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def save_dictionary_entries!(dictionary, dictionary_entries, opts = {})
        response = save_dictionary_entries(dictionary, dictionary_entries, opts)

        response.wait(opts)
      end

      # Replace entries for a given dictionary
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param dictionary_entries [Array<Hash>] array of dictionary entries
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def replace_dictionary_entries(dictionary, dictionary_entries, opts = {})
        response = @transporter.write(
          :POST,
          path_encode('/1/dictionaries/%s/batch', dictionary),
          { clearExistingDictionaryEntries: true, requests: chunk('addEntry', dictionary_entries) },
          opts
        )

        DictionaryResponse.new(self, response)
      end

      # Replace entries for a given dictionary and wait for the task to finish
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param dictionary_entries [Array<Hash>] array of dictionary entries
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def replace_dictionary_entries!(dictionary, dictionary_entries, opts = {})
        response = replace_dictionary_entries(dictionary, dictionary_entries, opts)

        response.wait(opts)
      end

      # Delete entries for a given dictionary
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param object_ids [Array<Hash>] array of object ids
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def delete_dictionary_entries(dictionary, object_ids, opts = {})
        request  = object_ids.map do |object_id|
          { objectID: object_id }
        end
        response = @transporter.write(
          :POST,
          path_encode('/1/dictionaries/%s/batch', dictionary),
          { clearExistingDictionaryEntries: false, requests: chunk('deleteEntry', request) },
          opts
        )

        DictionaryResponse.new(self, response)
      end

      # Delete entries for a given dictionary and wait for the task to finish
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param object_ids [Array<Hash>] array of object ids
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def delete_dictionary_entries!(dictionary, object_ids, opts = {})
        response = delete_dictionary_entries(dictionary, object_ids, opts)

        response.wait(opts)
      end

      # Clear all entries for a given dictionary
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def clear_dictionary_entries(dictionary, opts = {})
        replace_dictionary_entries(dictionary, [], opts)
      end

      # Clear all entries for a given dictionary and wait for the task to finish
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def clear_dictionary_entries!(dictionary, opts = {})
        response = replace_dictionary_entries(dictionary, [], opts)

        response.wait(opts)
      end

      # Search entries for a given dictionary
      #
      # @param dictionary [String] dictionary name. Can be either 'stopwords', 'plurals' or 'compounds'
      # @param query [String] query to send
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def search_dictionary_entries(dictionary, query, opts = {})
        @transporter.read(
          :POST,
          path_encode('/1/dictionaries/%s/search', dictionary),
          { query: query },
          opts
        )
      end

      # Set settings for all the dictionaries
      #
      # @param dictionary_settings [Hash]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def set_dictionary_settings(dictionary_settings, opts = {})
        response = @transporter.write(:PUT, '/1/dictionaries/*/settings', dictionary_settings, opts)

        DictionaryResponse.new(self, response)
      end

      # Set settings for all the dictionaries and wait for the task to finish
      #
      # @param dictionary_settings [Hash]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return DictionaryResponse
      #
      def set_dictionary_settings!(dictionary_settings, opts = {})
        response = set_dictionary_settings(dictionary_settings, opts)

        response.wait(opts)
      end

      # Retrieve settings for all the dictionaries
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def get_dictionary_settings(opts = {})
        @transporter.read(:GET, '/1/dictionaries/*/settings', {}, opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # MISC METHODS
      # # # # # # # # # # # # # # # # # # # # #

      # Method available to make custom requests to the API
      #
      def custom_request(data, uri, method, call_type, opts = {})
        if call_type == WRITE
          @transporter.write(method.to_sym, uri, data, opts)
        elsif call_type == READ
          @transporter.read(method.to_sym, uri, data, opts)
        end
      end
    end
  end
end
