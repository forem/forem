require 'securerandom'
require_relative 'base_test'

class SearchClientTest < BaseTest
  describe 'customize search client' do
    def test_with_custom_adapter
      client = Algolia::Search::Client.new(@@search_config, adapter: 'httpclient')
      index  = client.init_index(get_test_index_name('test_custom_adapter'))

      index.save_object!({ name: 'test', data: 10 }, { auto_generate_object_id_if_not_exist: true })
      response = index.search('test')

      refute_empty response[:hits]
      assert_equal 'test', response[:hits][0][:name]
      assert_equal 10, response[:hits][0][:data]
    end

    def test_with_custom_requester
      client = Algolia::Search::Client.new(@@search_config, http_requester: MockRequester.new)
      index  = client.init_index(get_test_index_name('test_custom_requester'))

      response = index.search('test')

      refute_nil response[:hits]
    end

    def test_without_providing_config
      client   = Algolia::Search::Client.create(APPLICATION_ID_1, ADMIN_KEY_1)
      index    = client.init_index(get_test_index_name('test_no_config'))
      index.save_object!({ name: 'test', data: 10 }, { auto_generate_object_id_if_not_exist: true })
      response = index.search('test')

      refute_empty response[:hits]
      assert_equal 'test', response[:hits][0][:name]
      assert_equal 10, response[:hits][0][:data]
    end
  end

  describe 'copy and move index' do
    def before_all
      super
      @index_name = get_test_index_name('copy_index')
      @index      = @@search_client.init_index(@index_name)
    end

    def test_copy_and_move_index
      responses = Algolia::MultipleResponse.new

      objects = [
        { objectID: 'one', company: 'apple' },
        { objectID: 'two', company: 'algolia' }
      ]
      responses.push(@index.save_objects(objects))

      settings = { attributesForFaceting: ['company'] }
      responses.push(@index.set_settings(settings))

      synonym = {
        objectID: 'google_placeholder',
        type: 'placeholder',
        placeholder: '<GOOG>',
        replacements: %w(Google GOOG)
      }
      responses.push(@index.save_synonym(synonym))

      rule = {
        objectID: 'company_auto_faceting',
        condition: {
          anchoring: 'contains',
          pattern: '{facet:company}'
        },
        consequence: {
          params: { automaticFacetFilters: ['company'] }
        }
      }
      responses.push(@index.save_rule(rule))

      responses.wait

      copy_settings_index  = @@search_client.init_index(get_test_index_name('copy_index_settings'))
      copy_rules_index     = @@search_client.init_index(get_test_index_name('copy_index_rules'))
      copy_synonyms_index  = @@search_client.init_index(get_test_index_name('copy_index_synonyms'))
      copy_full_copy_index = @@search_client.init_index(get_test_index_name('copy_index_full_copy'))
      @@search_client.copy_settings!(@index_name, copy_settings_index.name)
      @@search_client.copy_rules!(@index_name, copy_rules_index.name)
      @@search_client.copy_synonyms!(@index_name, copy_synonyms_index.name)
      @@search_client.copy_index!(@index_name, copy_full_copy_index.name)

      assert_equal @index.get_settings, copy_settings_index.get_settings
      assert_equal @index.get_rule(rule[:objectID]), copy_rules_index.get_rule(rule[:objectID])
      assert_equal @index.get_synonym(synonym[:objectID]), copy_synonyms_index.get_synonym(synonym[:objectID])
      assert_equal @index.get_settings, copy_full_copy_index.get_settings
      assert_equal @index.get_rule(rule[:objectID]), copy_full_copy_index.get_rule(rule[:objectID])
      assert_equal @index.get_synonym(synonym[:objectID]), copy_full_copy_index.get_synonym(synonym[:objectID])

      moved_index = @@search_client.init_index(get_test_index_name('move_index'))
      @@search_client.move_index!(@index_name, moved_index.name)

      moved_index.get_synonym('google_placeholder')
      moved_index.get_rule('company_auto_faceting')
      assert_equal moved_index.get_settings[:attributesForFaceting], ['company']

      moved_index.browse_objects.each do |obj|
        assert_includes objects, obj
      end
    end
  end

  describe 'MCM' do
    def before_all
      super
      @mcm_client = Algolia::Search::Client.create(MCM_APPLICATION_ID, MCM_ADMIN_KEY)
    end

    def test_mcm
      clusters = @mcm_client.list_clusters
      assert_equal 2, clusters[:clusters].length

      cluster_name = clusters[:clusters][0][:clusterName]

      mcm_user_id0 = get_mcm_user_name(0)
      mcm_user_id1 = get_mcm_user_name(1)
      mcm_user_id2 = get_mcm_user_name(2)

      @mcm_client.assign_user_id(mcm_user_id0, cluster_name)
      @mcm_client.assign_user_ids([mcm_user_id1, mcm_user_id2], cluster_name)

      0.upto(2) do |i|
        retrieved_user = retrieve_user_id(i)
        assert_equal(retrieved_user, {
          userID: get_mcm_user_name(i),
          clusterName: cluster_name,
          nbRecords: 0,
          dataSize: 0
        })
      end

      refute_equal 0, @mcm_client.list_user_ids[:userIDs].length
      refute_equal 0, @mcm_client.get_top_user_ids[:topUsers].length

      0.upto(2) do |i|
        remove_user_id(i)
      end

      0.upto(2) do |i|
        assert_removed(i)
      end

      has_pending_mappings = @mcm_client.pending_mappings?({ retrieveMappings: true })
      refute_nil has_pending_mappings
      assert has_pending_mappings[:pending]
      assert has_pending_mappings[:clusters]
      assert_instance_of Hash, has_pending_mappings[:clusters]

      has_pending_mappings = @mcm_client.pending_mappings?({ retrieveMappings: false })
      refute_nil has_pending_mappings
      assert has_pending_mappings[:pending]
      refute has_pending_mappings[:clusters]
    end

    def retrieve_user_id(number)
      loop do
        begin
          return @mcm_client.get_user_id(get_mcm_user_name(number))
        rescue Algolia::AlgoliaHttpError => e
          if e.code != 404
            raise StandardError
          end
        end
      end
    end

    def remove_user_id(number)
      loop do
        begin
          return @mcm_client.remove_user_id(get_mcm_user_name(number))
        rescue Algolia::AlgoliaHttpError => e
          if e.code != 400
            raise StandardError
          end
        end
      end
    end

    def assert_removed(number)
      loop do
        begin
          return @mcm_client.get_user_id(get_mcm_user_name(number))
        rescue Algolia::AlgoliaHttpError => e
          if e.code == 404
            return true
          end
        end
      end
    end
  end

  describe 'API keys' do
    def before_all
      super
      response = @@search_client.add_api_key!(['search'], {
        description: 'A description',
        indexes: ['index'],
        maxHitsPerQuery: 1000,
        maxQueriesPerIPPerHour: 1000,
        queryParameters: 'typoTolerance=strict',
        referers: ['referer'],
        validity: 600
      })
      @api_key = @@search_client.get_api_key(response.raw_response[:key])
    end

    def teardown
      @@search_client.delete_api_key!(@api_key[:value])
    end

    def test_api_keys
      assert_equal ['search'], @api_key[:acl]
      assert_equal 'A description', @api_key[:description]

      api_keys = @@search_client.list_api_keys[:keys].map do |key|
        key[:value]
      end
      assert_includes api_keys, @api_key[:value]

      @@search_client.update_api_key!(@api_key[:value], { maxHitsPerQuery: 42 })
      updated_api_key = retry_test do
        @@search_client.get_api_key(@api_key[:value], test: 'test')
      end
      assert_equal 42, updated_api_key[:maxHitsPerQuery]

      @@search_client.delete_api_key!(@api_key[:value])

      exception = assert_raises Algolia::AlgoliaHttpError do
        @@search_client.get_api_key(@api_key[:value])
      end

      assert_equal 'Key does not exist', exception.message

      retry_test do
        @@search_client.restore_api_key!(@api_key[:value])
      end

      restored_key = retry_test do
        @@search_client.get_api_key(@api_key[:value])
      end

      refute_nil restored_key
    end
  end

  describe 'Get logs' do
    def test_logs
      @@search_client.list_indexes
      @@search_client.list_indexes

      assert_equal 2, @@search_client.get_logs({
        length: 2,
        offset: 0,
        type: 'all'
      })[:logs].length
    end
  end

  describe 'Multiple Operations' do
    def before_all
      @index1 = @@search_client.init_index(get_test_index_name('multiple_operations'))
      @index2 = @@search_client.init_index(get_test_index_name('multiple_operations_dev'))
    end

    def test_multiple_operations
      index_name1 = @index1.name
      index_name2 = @index2.name

      response = @@search_client.multiple_batch!([
        { indexName: index_name1, action: 'addObject', body: { firstname: 'Jimmie' } },
        { indexName: index_name1, action: 'addObject', body: { firstname: 'Jimmie' } },
        { indexName: index_name2, action: 'addObject', body: { firstname: 'Jimmie' } },
        { indexName: index_name2, action: 'addObject', body: { firstname: 'Jimmie' } }
      ])

      object_ids = response.raw_response[:objectIDs]
      objects    = @@search_client.multiple_get_objects([
        { indexName: index_name1, objectID: object_ids[0] },
        { indexName: index_name1, objectID: object_ids[1] },
        { indexName: index_name2, objectID: object_ids[2] },
        { indexName: index_name2, objectID: object_ids[3] }
      ])[:results]

      assert_equal object_ids[0], objects[0][:objectID]
      assert_equal object_ids[1], objects[1][:objectID]
      assert_equal object_ids[2], objects[2][:objectID]
      assert_equal object_ids[3], objects[3][:objectID]

      results = @@search_client.multiple_queries([
        { indexName: index_name1, params: to_query_string({ query: '', hitsPerPage: 2 }) },
        { indexName: index_name2, params: { query: '', hitsPerPage: 2 } }
      ], { strategy: 'none' })[:results]

      assert_equal 2, results.length
      assert_equal 2, results[0][:hits].length
      assert_equal 2, results[0][:nbHits]
      assert_equal 2, results[1][:hits].length
      assert_equal 2, results[1][:nbHits]

      results = @@search_client.multiple_queries([
        { indexName: index_name1, params: to_query_string({ query: '', hitsPerPage: 2 }) },
        { indexName: index_name2, params: to_query_string({ query: '', hitsPerPage: 2 }) }
      ], { strategy: 'stopIfEnoughMatches' })[:results]

      assert_equal 2, results.length
      assert_equal 2, results[0][:hits].length
      assert_equal 2, results[0][:nbHits]
      assert_equal 0, results[1][:hits].length
      assert_equal 0, results[1][:nbHits]
    end

    describe 'Secured API keys' do
      def test_secured_api_keys
        @index1 = @@search_client.init_index(get_test_index_name('secured_api_keys'))
        @index2 = @@search_client.init_index(get_test_index_name('secured_api_keys_dev'))
        @index1.save_object!({ objectID: 'one' })
        @index2.save_object!({ objectID: 'one' })

        now             = Time.now.to_i
        secured_api_key = Algolia::Search::Client.generate_secured_api_key(SEARCH_KEY_1, {
          validUntil: now + (10 * 60),
          restrictIndices: @index1.name
        })

        secured_client = Algolia::Search::Client.create(APPLICATION_ID_1, secured_api_key)
        secured_index1 = secured_client.init_index(@index1.name)
        secured_index2 = secured_client.init_index(@index2.name)

        res = retry_test do
          secured_index1.search('')
        end

        assert_equal 1, res[:hits].length

        exception = assert_raises Algolia::AlgoliaHttpError do
          secured_index2.search('')
        end

        assert_equal 403, exception.code
        assert_equal 'Index not allowed with this API key', exception.message
      end
    end

    describe 'Expired Secured API keys' do
      def test_expired_secured_api_keys
        now             = Time.now.to_i
        secured_api_key = Algolia::Search::Client.generate_secured_api_key('foo', {
          validUntil: now - (10 * 60)
        })
        remaining       = Algolia::Search::Client.get_secured_api_key_remaining_validity(secured_api_key)
        assert remaining < 0

        secured_api_key = Algolia::Search::Client.generate_secured_api_key('foo', {
          validUntil: now + (10 * 60)
        })
        remaining       = Algolia::Search::Client.get_secured_api_key_remaining_validity(secured_api_key)
        assert remaining > 0

        secured_api_key = Algolia::Search::Client.generate_secured_api_key('foo', {})
        exception       = assert_raises Algolia::AlgoliaError do
          Algolia::Search::Client.get_secured_api_key_remaining_validity(secured_api_key)
        end

        assert_equal 'The SecuredAPIKey doesn\'t have a validUntil parameter.', exception.message
      end
    end

    describe 'Custom Dictionaries' do
      def before_all
        @client = Algolia::Search::Client.create(APPLICATION_ID_2, ADMIN_KEY_2)
      end

      def test_stopwords_dictionaries
        entry_id = SecureRandom.hex
        assert_equal 0, @client.search_dictionary_entries('stopwords', entry_id)[:nbHits]

        entry = {
          objectID: entry_id,
          language: 'en',
          word: 'down'
        }
        @client.save_dictionary_entries!('stopwords', [entry])

        stopwords = @client.search_dictionary_entries('stopwords', entry_id)
        assert_equal 1, stopwords[:nbHits]
        assert_equal stopwords[:hits][0][:objectID], entry[:objectID]
        assert_equal stopwords[:hits][0][:word], entry[:word]

        @client.delete_dictionary_entries!('stopwords', [entry_id])
        assert_equal 0, @client.search_dictionary_entries('stopwords', entry_id)[:nbHits]

        old_dictionary_state   = @client.search_dictionary_entries('stopwords', '')
        old_dictionary_entries = old_dictionary_state[:hits].map do |hit|
          hit.reject { |key| key == :type }
        end

        @client.save_dictionary_entries!('stopwords', [entry])
        assert_equal 1, @client.search_dictionary_entries('stopwords', entry_id)[:nbHits]

        @client.replace_dictionary_entries!('stopwords', old_dictionary_entries)
        assert_equal 0, @client.search_dictionary_entries('stopwords', entry_id)[:nbHits]

        stopwords_settings = {
          disableStandardEntries: {
            stopwords: {
              en: true
            }
          }
        }

        @client.set_dictionary_settings!(stopwords_settings)

        assert_equal @client.get_dictionary_settings, stopwords_settings
      end

      def test_plurals_dictionaries
        entry_id = SecureRandom.hex
        assert_equal 0, @client.search_dictionary_entries('plurals', entry_id)[:nbHits]

        entry = {
          objectID: entry_id,
          language: 'fr',
          words: %w(cheval chevaux)
        }
        @client.save_dictionary_entries!('plurals', [entry])

        plurals = @client.search_dictionary_entries('plurals', entry_id)
        assert_equal 1, plurals[:nbHits]
        assert_equal plurals[:hits][0][:objectID], entry[:objectID]
        assert_equal plurals[:hits][0][:words], entry[:words]

        @client.delete_dictionary_entries!('plurals', [entry_id])
        assert_equal 0, @client.search_dictionary_entries('plurals', entry_id)[:nbHits]
      end

      def test_compounds_dictionaries
        entry_id = SecureRandom.hex
        assert_equal 0, @client.search_dictionary_entries('compounds', entry_id)[:nbHits]

        entry = {
          objectID: entry_id,
          language: 'de',
          word: 'kopfschmerztablette',
          decomposition: %w(kopf schmerz tablette)
        }
        @client.save_dictionary_entries!('compounds', [entry])

        compounds = @client.search_dictionary_entries('compounds', entry_id)
        assert_equal 1, compounds[:nbHits]
        assert_equal compounds[:hits][0][:objectID], entry[:objectID]
        assert_equal compounds[:hits][0][:word], entry[:word]
        assert_equal compounds[:hits][0][:decomposition], entry[:decomposition]

        @client.delete_dictionary_entries!('compounds', [entry_id])
        assert_equal 0, @client.search_dictionary_entries('compounds', entry_id)[:nbHits]
      end
    end
  end
end
