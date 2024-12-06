module Algolia
  module Search
    # Class Index
    class Index
      include CallType
      include Helpers

      attr_reader :name, :transporter, :config, :logger

      # Initialize an index
      #
      # @param name [String] name of the index
      # @param transporter [Object] transport object used for the connection
      # @param config [Config] a Config object which contains your APP_ID and API_KEY
      # @param logger [LoggerHelper] an optional LoggerHelper object to use
      #
      def initialize(name, transporter, config, logger = nil)
        @name        = name
        @transporter = transporter
        @config      = config
        @logger      = logger || LoggerHelper.create
      end

      # # # # # # # # # # # # # # # # # # # # #
      # MISC
      # # # # # # # # # # # # # # # # # # # # #

      # Wait the publication of a task on the server.
      # All server task are asynchronous and you can check with this method that the task is published.
      #
      # @param task_id the id of the task returned by server
      # @param time_before_retry the time in milliseconds before retry (default = 100ms)
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def wait_task(task_id, time_before_retry = Defaults::WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY, opts = {})
        loop do
          status = get_task_status(task_id, opts)
          if status == 'published'
            return
          end
          sleep(time_before_retry.to_f / 1000)
        end
      end

      # Check the status of a task on the server.
      # All server task are asynchronous and you can check the status of a task with this method.
      #
      # @param task_id [Integer] the id of the task returned by server
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def get_task_status(task_id, opts = {})
        res    = @transporter.read(:GET, path_encode('/1/indexes/%s/task/%s', @name, task_id), {}, opts)
        get_option(res, 'status')
      end

      # Delete the index content
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def clear_objects(opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/clear', @name), {}, opts)

        IndexingResponse.new(self, response)
      end

      # Delete the index content and wait for operation to complete
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def clear_objects!(opts = {})
        response = clear_objects(opts)
        response.wait(opts)
      end

      # Delete an existing index
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def delete(opts = {})
        response = @transporter.write(:DELETE, path_encode('/1/indexes/%s', @name), opts)

        IndexingResponse.new(self, response)
      end

      # Delete an existing index and wait for operation to complete
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      def delete!(opts = {})
        response = delete(opts)
        response.wait(opts)
      end

      # Find object by the given condition.
      #
      # Options can be passed in request_options body:
      #  - query (string): pass a query
      #  - paginate (bool): choose if you want to iterate through all the
      # documents (true) or only the first page (false). Default is true.
      # The function takes a block to filter the results from search query
      # Usage example:
      #  index.find_object({'query' => '', 'paginate' => true}) {|obj| obj.key?('company') and obj['company'] == 'Apple'}
      #
      # @param callback [Lambda] contains extra parameters to send with your query
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash|AlgoliaHttpError] the matching object and its position in the result set
      #
      def find_object(callback, opts = {})
        request_options = symbolize_hash(opts)
        paginate        = true
        page            = 0

        query    = request_options.delete(:query) || ''
        paginate = request_options.delete(:paginate) if request_options.has_key?(:paginate)

        has_next_page = true
        while has_next_page
          request_options[:page] = page
          res                    = symbolize_hash(search(query, request_options))

          res[:hits].each_with_index do |hit, i|
            if callback.call(hit)
              return {
                object: hit,
                position: i,
                page: page
              }
            end
          end

          has_next_page = page + 1 < res[:nbPages]
          raise AlgoliaHttpError.new(404, 'Object not found') unless paginate && has_next_page

          page += 1
        end
      end

      # Retrieve the given object position in a set of results.
      #
      # @param [Array] objects the result set to browse
      # @param [String] object_id the object to look for
      #
      # @return [Integer] position of the object, or -1 if it's not in the array
      #
      def self.get_object_position(objects, object_id)
        hits = get_option(objects, 'hits')
        hits.find_index { |hit| get_option(hit, 'objectID') == object_id } || -1
      end

      # Copy the current index to the given destination name
      #
      # @param name [String] destination index name
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def copy_to(name, opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/operation', @name), { operation: 'copy', destination: name }, opts)

        IndexingResponse.new(self, response)
      end

      # Move the current index to the given destination name
      #
      # @param name [String] destination index name
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def move_to(name, opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/operation', @name), { operation: 'move', destination: name }, opts)

        IndexingResponse.new(self, response)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # INDEXING
      # # # # # # # # # # # # # # # # # # # # #

      # Retrieve one object from the index
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_object(object_id, opts = {})
        @transporter.read(:GET, path_encode('/1/indexes/%s/%s', @name, object_id), {}, opts)
      end

      # Retrieve one or more objects in a single API call
      #
      # @param object_ids [Array]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_objects(object_ids, opts = {})
        request_options        = symbolize_hash(opts)
        attributes_to_retrieve = get_option(request_options, 'attributesToRetrieve')
        request_options.delete(:attributesToRetrieve)

        requests = []
        object_ids.each do |object_id|
          request = { indexName: @name, objectID: object_id.to_s }

          if attributes_to_retrieve
            request[:attributesToRetrieve] = attributes_to_retrieve
          end

          requests.push(request)
        end

        @transporter.read(:POST, '/1/indexes/*/objects', { 'requests': requests }, opts)
      end

      # Add an object to the index
      #
      # @param object [Hash] the object to save
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def save_object(object, opts = {})
        save_objects([object], opts)
      end

      # Add an object to the index and wait for operation to complete
      #
      # @param object [Hash] the object to save
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def save_object!(object, opts = {})
        response = save_objects([object], opts)
        response.wait(opts)
      end

      # Add several objects to the index
      #
      # @param objects [Array] the objects to save
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def save_objects(objects, opts = {})
        request_options    = symbolize_hash(opts)
        generate_object_id = request_options[:auto_generate_object_id_if_not_exist] || false
        request_options.delete(:auto_generate_object_id_if_not_exist)
        if generate_object_id
          IndexingResponse.new(self, raw_batch(chunk('addObject', objects), request_options))
        else
          IndexingResponse.new(self, raw_batch(chunk('updateObject', objects, true), request_options))
        end
      end

      # Add several objects to the index and wait for operation to complete
      #
      # @param objects [Array] the objects to save
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def save_objects!(objects, opts = {})
        response = save_objects(objects, opts)
        response.wait(opts)
      end

      # Partially update an object
      #
      # @param object [String] object ID to partially update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def partial_update_object(object, opts = {})
        partial_update_objects([object], opts)
      end

      # Partially update an object and wait for operation to complete
      #
      # @param object [String] object ID to partially update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def partial_update_object!(object, opts = {})
        response     = partial_update_objects([object], opts)
        response.wait(opts)
      end

      # Partially update several objects
      #
      # @param objects [Array] array of objectIDs to partially update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def partial_update_objects(objects, opts = {})
        generate_object_id = false
        request_options    = symbolize_hash(opts)
        if get_option(request_options, 'createIfNotExists')
          generate_object_id = true
        end
        request_options.delete(:createIfNotExists)

        if generate_object_id
          IndexingResponse.new(self, raw_batch(chunk('partialUpdateObject', objects), request_options))
        else
          IndexingResponse.new(self, raw_batch(chunk('partialUpdateObjectNoCreate', objects), request_options))
        end
      end

      # Partially update several objects and wait for operation to complete
      #
      # @param objects [Array] array of objectIDs to partially update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def partial_update_objects!(objects, opts = {})
        response = partial_update_objects(objects, opts)
        response.wait(opts)
      end

      # Delete an existing object from an index
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_object(object_id, opts = {})
        delete_objects([object_id], opts)
      end

      # Delete an existing object from an index and wait for operation to complete
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_object!(object_id, opts = {})
        response = delete_objects([object_id], opts)
        response.wait(opts)
      end

      # Delete several existing objects from an index
      #
      # @param object_ids [Array]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_objects(object_ids, opts = {})
        objects = object_ids.map do |object_id|
          { objectID: object_id }
        end

        IndexingResponse.new(self, raw_batch(chunk('deleteObject', objects), opts))
      end

      # Delete several existing objects from an index and wait for operation to complete
      #
      # @param object_ids [Array]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_objects!(object_ids, opts = {})
        response     = delete_objects(object_ids, opts)
        response.wait(opts)
      end

      # Delete all records matching the query
      #
      # @param filters [Hash]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_by(filters, opts = {})
        response = @transporter.write(:POST, path_encode('/1/indexes/%s/deleteByQuery', @name), filters, opts)

        IndexingResponse.new(self, response)
      end

      # Delete all records matching the query and wait for operation to complete
      #
      # @param filters [Hash]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_by!(filters, opts = {})
        response = delete_by(filters, opts)

        response.wait(opts)
      end

      # Send a batch request
      #
      # @param requests [Hash] hash containing the requests to batch
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def batch(requests, opts = {})
        response = raw_batch(requests, opts)

        IndexingResponse.new(self, response)
      end

      # Send a batch request and wait for operation to complete
      #
      # @param requests [Hash] hash containing the requests to batch
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def batch!(requests, opts = {})
        response     = batch(requests, opts)
        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # QUERY RULES
      # # # # # # # # # # # # # # # # # # # # #

      # Retrieve the Rule with the specified objectID
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_rule(object_id, opts = {})
        @transporter.read(:GET, path_encode('/1/indexes/%s/rules/%s', @name, object_id), {}, opts)
      end

      # Create or update a rule
      #
      # @param rule [Hash] a hash containing a rule objectID and different conditions/consequences
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_rule(rule, opts = {})
        save_rules([rule], opts)
      end

      # Create or update a rule and wait for operation to complete
      #
      # @param rule [Hash] a hash containing a rule objectID and different conditions/consequences
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_rule!(rule, opts = {})
        response = save_rules([rule], opts)
        response.wait(opts)
      end

      # Create or update rules
      #
      # @param rules [Array] an array of hashes containing a rule objectID and different conditions/consequences
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_rules(rules, opts = {})
        if rules.is_a?(RuleIterator)
          iterated = []
          rules.each do |rule|
            iterated.push(rule)
          end
          rules    = iterated
        end

        if rules.empty?
          return []
        end

        forward_to_replicas  = false
        clear_existing_rules = false
        request_options      = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end

        if request_options[:clearExistingRules]
          clear_existing_rules = true
          request_options.delete(:clearExistingRules)
        end

        rules.each do |rule|
          get_object_id(rule)
        end

        response = @transporter.write(:POST, path_encode('/1/indexes/%s/rules/batch', @name) + handle_params({ forwardToReplicas: forward_to_replicas, clearExistingRules: clear_existing_rules }), rules, request_options)

        IndexingResponse.new(self, response)
      end

      # Create or update rules and wait for operation to complete
      #
      # @param rules [Array] an array of hashes containing a rule objectID and different conditions/consequences
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_rules!(rules, opts = {})
        response = save_rules(rules, opts)
        response.wait(opts)
      end

      # Delete all Rules in the index
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def clear_rules(opts = {})
        forward_to_replicas = false
        request_options     = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end

        response = @transporter.write(:POST, path_encode('1/indexes/%s/rules/clear', @name) + handle_params({ forwardToReplicas: forward_to_replicas }), '', request_options)

        IndexingResponse.new(self, response)
      end

      # Delete all Rules in the index and wait for operation to complete
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def clear_rules!(opts = {})
        response     = clear_rules(opts)
        response.wait(opts)
      end

      # Delete the Rule with the specified objectID
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_rule(object_id, opts = {})
        forward_to_replicas = false
        request_options     = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end

        response = @transporter.write(
          :DELETE,
          path_encode('1/indexes/%s/rules/%s', @name, object_id) + handle_params({ forwardToReplicas: forward_to_replicas }),
          '',
          request_options
        )

        IndexingResponse.new(self, response)
      end

      # Delete the Rule with the specified objectID and wait for operation to complete
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_rule!(object_id, opts = {})
        response = delete_rule(object_id, opts)
        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # SYNONYMS
      # # # # # # # # # # # # # # # # # # # # #

      # Fetch a synonym object identified by its objectID
      #
      # @param object_id [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_synonym(object_id, opts = {})
        @transporter.read(:GET, path_encode('/1/indexes/%s/synonyms/%s', @name, object_id), {}, opts)
      end

      # Create a new synonym object or update the existing synonym object with the given object ID
      #
      # @param synonym [Hash] Synonym object
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_synonym(synonym, opts = {})
        save_synonyms([synonym], opts)
      end

      # Create a new synonym object or update the existing synonym object with the given object ID
      # and wait for operation to finish
      #
      # @param synonym [Hash] Synonym object
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_synonym!(synonym, opts = {})
        response     = save_synonyms([synonym], opts)
        response.wait(opts)
      end

      # Create/update multiple synonym objects at once, potentially replacing the entire list of synonyms if
      # replaceExistingSynonyms is true
      #
      # @param synonyms [Array] Array of Synonym objects
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_synonyms(synonyms, opts = {})
        if synonyms.is_a?(SynonymIterator)
          iterated = []
          synonyms.each do |synonym|
            iterated.push(synonym)
          end
          synonyms = iterated
        end

        if synonyms.empty?
          return []
        end

        synonyms.each do |synonym|
          get_object_id(synonym)
        end

        forward_to_replicas       = false
        replace_existing_synonyms = false

        request_options = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end

        if request_options[:replaceExistingSynonyms]
          replace_existing_synonyms = true
          request_options.delete(:replaceExistingSynonyms)
        end
        response = @transporter.write(
          :POST,
          path_encode('/1/indexes/%s/synonyms/batch', @name) + handle_params({ forwardToReplicas: forward_to_replicas, replaceExistingSynonyms: replace_existing_synonyms }),
          synonyms,
          request_options
        )

        IndexingResponse.new(self, response)
      end

      # Create/update multiple synonym objects at once, potentially replacing the entire list of synonyms if
      # replaceExistingSynonyms is true and wait for operation to complete
      #
      # @param synonyms [Array] Array of Synonym objects
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def save_synonyms!(synonyms, opts = {})
        response = save_synonyms(synonyms, opts)
        response.wait(opts)
      end

      # Delete all synonyms from the index
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def clear_synonyms(opts = {})
        forward_to_replicas = false
        request_options     = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end
        response = @transporter.write(
          :POST,
          path_encode('1/indexes/%s/synonyms/clear', @name) + handle_params({ forwardToReplicas: forward_to_replicas }),
          '',
          request_options
        )

        IndexingResponse.new(self, response)
      end

      # Delete all synonyms from the index and wait for operation to complete
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def clear_synonyms!(opts = {})
        response     = clear_synonyms(opts)
        response.wait(opts)
      end

      # Delete a single synonyms set, identified by the given objectID
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_synonym(object_id, opts = {})
        forward_to_replicas = false
        request_options     = symbolize_hash(opts)

        if request_options[:forwardToReplicas]
          forward_to_replicas = true
          request_options.delete(:forwardToReplicas)
        end
        response = @transporter.write(
          :DELETE,
          path_encode('1/indexes/%s/synonyms/%s', @name, object_id) + handle_params({ forwardToReplicas: forward_to_replicas }),
          '',
          request_options
        )

        IndexingResponse.new(self, response)
      end

      # Delete a single synonyms set, identified by the given objectID and wait for operation to complete
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def delete_synonym!(object_id, opts = {})
        response     = delete_synonym(object_id, opts)
        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # BROWSING
      # # # # # # # # # # # # # # # # # # # # #

      # Browse all index content
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Enumerator, ObjectIterator]
      #
      def browse_objects(opts = {}, &block)
        if block_given?
          ObjectIterator.new(@transporter, @name, opts).each(&block)
        else
          ObjectIterator.new(@transporter, @name, opts)
        end
      end

      # Browse all rules
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Enumerator, RuleIterator]
      #
      def browse_rules(opts = {}, &block)
        if block_given?
          RuleIterator.new(@transporter, @name, opts).each(&block)
        else
          RuleIterator.new(@transporter, @name, opts)
        end
      end

      # Browse all synonyms
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Enumerator, SynonymIterator]
      #
      def browse_synonyms(opts = {}, &block)
        if block_given?
          SynonymIterator.new(@transporter, @name, opts).each(&block)
        else
          SynonymIterator.new(@transporter, @name, opts)
        end
      end

      # # # # # # # # # # # # # # # # # # # # #
      # REPLACING
      # # # # # # # # # # # # # # # # # # # # #

      # Replace all objects in the index
      #
      # @param objects [Array] Array of objects
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Enumerator, SynonymIterator]
      #
      def replace_all_objects(objects, opts = {})
        safe            = false
        request_options = symbolize_hash(opts)
        if request_options[:safe]
          safe = true
          request_options.delete(:safe)
        end

        tmp_index_name   = @name + '_tmp_' + rand(10000000).to_s
        copy_to_response = copy_to(tmp_index_name, request_options.merge({ scope: %w(settings synonyms rules) }))

        if safe
          copy_to_response.wait
        end

        # TODO: consider create a new client with state of retry is shared
        tmp_client = Algolia::Search::Client.new(@config, { logger: logger })
        tmp_index  = tmp_client.init_index(tmp_index_name)

        save_objects_response = tmp_index.save_objects(objects, request_options)

        if safe
          save_objects_response.wait
        end

        move_to_response = tmp_index.move_to(@name)
        if safe
          move_to_response.wait
        end
      end

      # Replace all objects in the index and wait for the operation to complete
      #
      # @param objects [Array] Array of objects
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Enumerator, SynonymIterator]
      #
      def replace_all_objects!(objects, opts = {})
        replace_all_objects(objects, opts.merge(safe: true))
      end

      # Replace all rules in the index
      #
      # @param rules [Array] Array of rules
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def replace_all_rules(rules, opts = {})
        request_options                      = symbolize_hash(opts)
        request_options[:clearExistingRules] = true

        save_rules(rules, request_options)
      end

      # Replace all rules in the index and wait for the operation to complete
      #
      # @param rules [Array] Array of rules
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def replace_all_rules!(rules, opts = {})
        request_options                      = symbolize_hash(opts)
        request_options[:clearExistingRules] = true

        save_rules!(rules, request_options)
      end

      # Replace all synonyms in the index
      #
      # @param synonyms [Array] Array of synonyms
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def replace_all_synonyms(synonyms, opts = {})
        request_options                           = symbolize_hash(opts)
        request_options[:replaceExistingSynonyms] = true

        save_synonyms(synonyms, request_options)
      end

      # Replace all synonyms in the index and wait for the operation to complete
      #
      # @param synonyms [Array] Array of synonyms
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Array, IndexingResponse]
      #
      def replace_all_synonyms!(synonyms, opts = {})
        request_options                           = symbolize_hash(opts)
        request_options[:replaceExistingSynonyms] = true

        save_synonyms!(synonyms, request_options)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # SEARCHING
      # # # # # # # # # # # # # # # # # # # # #

      # Perform a search on the index
      #
      # @param query the full text query
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def search(query, opts = {})
        @transporter.read(:POST, path_encode('/1/indexes/%s/query', @name), { 'query': query.to_s }, opts)
      end

      # Search for values of a given facet, optionally restricting the returned values to those contained
      # in objects matching other search criteria
      #
      # @param facet_name [String]
      # @param facet_query [String]
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def search_for_facet_values(facet_name, facet_query, opts = {})
        @transporter.read(:POST, path_encode('/1/indexes/%s/facets/%s/query', @name, facet_name),
                          { 'facetQuery': facet_query }, opts)
      end

      # Search or browse all synonyms, optionally filtering them by type
      #
      # @param query [String] Search for specific synonyms matching this string
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def search_synonyms(query, opts = {})
        @transporter.read(:POST, path_encode('/1/indexes/%s/synonyms/search', @name), { query: query.to_s }, opts)
      end

      # Search or browse all rules, optionally filtering them by type
      #
      # @param query [String] Search for specific rules matching this string
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def search_rules(query, opts = {})
        @transporter.read(:POST, path_encode('/1/indexes/%s/rules/search', @name), { query: query.to_s }, opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # SETTINGS
      # # # # # # # # # # # # # # # # # # # # #

      # Retrieve index settings
      #
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [Hash]
      #
      def get_settings(opts = {})
        opts_default = {
          getVersion: 2
        }
        opts         = opts_default.merge(opts)
        response     = @transporter.read(:GET, path_encode('/1/indexes/%s/settings', @name), {}, opts)

        deserialize_settings(response, @config.symbolize_keys)
      end

      # Update some index settings. Only specified settings are overridden
      #
      # @param settings [Hash] the settings to update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def set_settings(settings, opts = {})
        request_options      = symbolize_hash(opts)
        forward_to_replicas  = request_options.delete(:forwardToReplicas) || false

        response = @transporter.write(
          :PUT,
          path_encode('/1/indexes/%s/settings', @name) + handle_params({ forwardToReplicas: forward_to_replicas }),
          settings,
          request_options
        )

        IndexingResponse.new(self, response)
      end

      # Update some index settings and wait for operation to complete.
      # Only specified settings are overridden
      #
      # @param settings [Hash] the settings to update
      # @param opts [Hash] contains extra parameters to send with your query
      #
      # @return [IndexingResponse]
      #
      def set_settings!(settings, opts = {})
        response = set_settings(settings, opts)
        response.wait(opts)
      end

      # # # # # # # # # # # # # # # # # # # # #
      # EXISTS
      # # # # # # # # # # # # # # # # # # # # #

      # Checks if the current index exists
      #
      # @return [Boolean]
      #
      def exists
        begin
          get_settings
        rescue AlgoliaHttpError => e
          if e.code == 404
            return false
          end

          raise e
        end
        true
      end

      #
      # Aliases the exists method
      #
      alias_method :exists?, :exists

      # # # # # # # # # # # # # # # # # # # # #
      # PRIVATE
      # # # # # # # # # # # # # # # # # # # # #

      private

      def raw_batch(requests, opts)
        @transporter.write(:POST, path_encode('/1/indexes/%s/batch', @name), { requests: requests }, opts)
      end
    end
  end
end
