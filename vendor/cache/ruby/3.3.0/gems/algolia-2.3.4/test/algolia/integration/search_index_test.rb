require 'httpclient'
require_relative 'base_test'

class SearchIndexTest < BaseTest
  describe 'pass request options' do
    def before_all
      super
      @index = @@search_client.init_index(get_test_index_name('options'))
    end

    def test_with_wrong_credentials
      exception = assert_raises Algolia::AlgoliaHttpError do
        @index.save_object(generate_object('111'), {
          headers: {
            'X-Algolia-Application-Id' => 'XXXXX',
            'X-Algolia-API-Key' => 'XXXXX'
          }
        })
      end

      assert_equal 'Invalid Application-ID or API key', exception.message
    end
  end

  describe 'save objects' do
    def before_all
      super
      @index = @@search_client.init_index(get_test_index_name('indexing'))
    end

    def retrieve_last_object_ids(responses)
      responses.last.raw_response[:objectIDs]
    end

    def test_save_objects
      responses  = Algolia::MultipleResponse.new
      object_ids = []

      obj1     = generate_object('obj1')
      responses.push(@index.save_object(obj1))
      object_ids.push(retrieve_last_object_ids(responses))
      obj2     = generate_object
      response = @index.save_object(obj2, { auto_generate_object_id_if_not_exist: true })
      responses.push(response)
      object_ids.push(retrieve_last_object_ids(responses))
      responses.push(@index.save_objects([]))
      object_ids.push(retrieve_last_object_ids(responses))
      obj3     = generate_object('obj3')
      obj4     = generate_object('obj4')
      responses.push(@index.save_objects([obj3, obj4]))
      object_ids.push(retrieve_last_object_ids(responses))
      obj5     = generate_object
      obj6     = generate_object
      responses.push(@index.save_objects([obj5, obj6], { auto_generate_object_id_if_not_exist: true }))
      object_ids.push(retrieve_last_object_ids(responses))
      object_ids.flatten!
      objects  = 1.upto(1000).map do |i|
        generate_object(i.to_s)
      end

      @index.config.batch_size = 100
      responses.push(@index.save_objects(objects))
      responses.wait

      assert_equal obj1[:property], @index.get_object(object_ids[0])[:property]
      assert_equal obj2[:property], @index.get_object(object_ids[1])[:property]
      assert_equal obj3[:property], @index.get_object(object_ids[2])[:property]
      assert_equal obj4[:property], @index.get_object(object_ids[3])[:property]
      assert_equal obj5[:property], @index.get_object(object_ids[4])[:property]
      assert_equal obj6[:property], @index.get_object(object_ids[5])[:property]

      results = @index.get_objects((1..1000).to_a)[:results]

      results.each do |obj|
        assert_includes(objects, obj)
      end

      assert_equal objects.length, results.length
      browsed_objects = []
      @index.browse_objects do |hit|
        browsed_objects.push(hit)
      end

      assert_equal 1006, browsed_objects.length
      objects.each do |obj|
        assert_includes(browsed_objects, obj)
      end

      [obj1, obj3, obj4].each do |obj|
        assert_includes(browsed_objects, obj)
      end

      responses = Algolia::MultipleResponse.new

      obj1[:property] = 'new property'
      responses.push(@index.partial_update_object(obj1))

      obj3[:property] = 'new property 3'
      obj4[:property] = 'new property 4'
      responses.push(@index.partial_update_objects([obj3, obj4]))

      responses.wait

      assert_equal obj1[:property], @index.get_object(object_ids[0])[:property]
      assert_equal obj3[:property], @index.get_object(object_ids[2])[:property]
      assert_equal obj4[:property], @index.get_object(object_ids[3])[:property]

      delete_by_obj = { objectID: 'obj_del_by', _tags: 'algolia', property: 'property' }
      @index.save_object!(delete_by_obj)

      responses = Algolia::MultipleResponse.new

      responses.push(@index.delete_object(object_ids.shift))
      responses.push(@index.delete_by({ tagFilters: ['algolia'] }))
      responses.push(@index.delete_objects(object_ids))
      responses.push(@index.clear_objects)

      responses.wait

      browsed_objects = []
      @index.browse_objects do |hit|
        browsed_objects.push(hit)
      end

      assert_equal 0, browsed_objects.length
    end

    def test_save_object_without_object_id_and_fail
      exception = assert_raises Algolia::AlgoliaError do
        @index.save_object(generate_object)
      end

      assert_equal "Missing 'objectID'", exception.message
    end

    def test_save_objects_with_single_object_and_fail
      exception = assert_raises Algolia::AlgoliaError do
        @index.save_objects(generate_object)
      end

      assert_equal 'argument must be an array of objects', exception.message
    end

    def test_save_objects_with_array_of_integers_and_fail
      exception = assert_raises Algolia::AlgoliaError do
        @index.save_objects([2222, 3333])
      end

      assert_equal 'argument must be an array of object, got: 2222', exception.message
    end
  end

  describe 'settings' do
    def before_all
      super
      @index_name = get_test_index_name('settings')
      @index      = @@search_client.init_index(@index_name)
    end

    def test_settings
      @index.save_object!(generate_object('obj1'))

      settings = {
        searchableAttributes: %w(attribute1 attribute2 attribute3 ordered(attribute4) unordered(attribute5)),
        attributesForFaceting: %w(attribute1 filterOnly(attribute2) searchable(attribute3)),
        unretrievableAttributes: %w(
          attribute1
          attribute2
        ),
        attributesToRetrieve: %w(
          attribute3
          attribute4
        ),
        ranking: %w(asc(attribute1) desc(attribute2) attribute custom exact filters geo proximity typo words),
        customRanking: %w(asc(attribute1) desc(attribute1)),
        replicas: [
          @index_name + '_replica1',
          @index_name + '_replica2'
        ],
        maxValuesPerFacet: 100,
        sortFacetValuesBy: 'count',
        attributesToHighlight: %w(
          attribute1
          attribute2
        ),
        attributesToSnippet: %w(attribute1:10 attribute2:8),
        highlightPreTag: '<strong>',
        highlightPostTag: '</strong>',
        snippetEllipsisText: ' and so on.',
        restrictHighlightAndSnippetArrays: true,
        hitsPerPage: 42,
        paginationLimitedTo: 43,
        minWordSizefor1Typo: 2,
        minWordSizefor2Typos: 6,
        typoTolerance: 'false',
        allowTyposOnNumericTokens: false,
        ignorePlurals: true,
        disableTypoToleranceOnAttributes: %w(
          attribute1
          attribute2
        ),
        disableTypoToleranceOnWords: %w(
          word1
          word2
        ),
        separatorsToIndex: '()[]',
        queryType: 'prefixNone',
        removeWordsIfNoResults: 'allOptional',
        advancedSyntax: true,
        optionalWords: %w(
          word1
          word2
        ),
        removeStopWords: true,
        disablePrefixOnAttributes: %w(
          attribute1
          attribute2
        ),
        disableExactOnAttributes: %w(
          attribute1
          attribute2
        ),
        exactOnSingleWordQuery: 'word',
        enableRules: false,
        numericAttributesForFiltering: %w(
          attribute1
          attribute2
        ),
        allowCompressionOfIntegerArray: true,
        attributeForDistinct: 'attribute1',
        distinct: 2,
        replaceSynonymsInHighlight: false,
        minProximity: 7,
        responseFields: %w(
          hits
          hitsPerPage
        ),
        maxFacetHits: 100,
        camelCaseAttributes: %w(
          attribute1
          attribute2
        ),
        decompoundedAttributes: {
          de: %w(attribute1 attribute2),
          fi: ['attribute3']
        },
        keepDiacriticsOnCharacters: 'øé',
        queryLanguages: %w(
          en
          fr
        ),
        alternativesAsExact: ['ignorePlurals'],
        advancedSyntaxFeatures: ['exactPhrase'],
        userData: {
          customUserData: 42.0
        },
        indexLanguages: ['ja']
      }

      @index.set_settings!(settings)

      # Because the response settings dict contains the extra version key, we
      # also add it to the expected settings dict to prevent the test to fail
      # for a missing key.
      settings[:version] = 2

      assert_equal @index.get_settings, settings

      settings[:typoTolerance]   = 'min'
      settings[:ignorePlurals]   = %w(en fr)
      settings[:removeStopWords] = %w(en fr)
      settings[:distinct]        = true

      @index.set_settings!(settings)

      assert_equal @index.get_settings, settings

      # check that the forwardToReplicas parameter is passed correctly
      assert @index.set_settings!(settings, { forwardToReplicas: true })
    end

    # Check version 1 API calling (ref. PR #473)
    def test_version_param
      @index.save_object!(generate_object('obj1')) # create index

      # Check response's version value by actual access
      assert_equal 2, @index.get_settings[:version]
      assert_equal 1, @index.get_settings(getVersion: 1)[:version]
      assert_equal 2, @index.get_settings(getVersion: 2)[:version]

      # Check API endpoint handling by mock access
      requester = MockRequester.new
      client    = Algolia::Search::Client.new(@@search_config, http_requester: requester)
      index     = client.init_index(@index_name)

      index.get_settings # default
      index.get_settings(getVersion: 1)
      index.get_settings(getVersion: 2)

      assert_requests(
        requester,
        [
          { method: :get, path: "/1/indexes/#{@index_name}/settings?getVersion=2" },
          { method: :get, path: "/1/indexes/#{@index_name}/settings?getVersion=1" },
          { method: :get, path: "/1/indexes/#{@index_name}/settings?getVersion=2" }
        ]
      )
    end
  end

  describe 'search' do
    def before_all
      super
      @index = @@search_client.init_index(get_test_index_name('search'))
      @index.save_objects!(create_employee_records, { auto_generate_object_id_if_not_exist: true })
      @index.set_settings!(attributesForFaceting: ['searchable(company)'])
    end

    def test_search_objects
      response = @index.search('algolia')

      assert_equal 2, response[:nbHits]
      assert_equal 0, Algolia::Search::Index.get_object_position(response, 'nicolas-dessaigne')
      assert_equal 1, Algolia::Search::Index.get_object_position(response, 'julien-lemoine')
      assert_equal(-1, Algolia::Search::Index.get_object_position(response, ''))
    end

    def test_find_objects
      exception = assert_raises Algolia::AlgoliaHttpError do
        @index.find_object(-> (_hit) { false }, { query: '', paginate: false })
      end

      assert_equal 'Object not found', exception.message

      response = @index.find_object(-> (_hit) { true }, { query: '', paginate: false })
      assert_equal 0, response[:position]
      assert_equal 0, response[:page]

      condition = -> (obj) do
        obj.has_key?(:company) && obj[:company] == 'Apple'
      end

      exception = assert_raises Algolia::AlgoliaHttpError do
        @index.find_object(condition, { query: 'algolia', paginate: false })
      end

      assert_equal 'Object not found', exception.message

      exception = assert_raises Algolia::AlgoliaHttpError do
        @index.find_object(condition, { query: '', paginate: false, hitsPerPage: 5 })
      end

      assert_equal 'Object not found', exception.message

      response = @index.find_object(condition, { query: '', paginate: true, hitsPerPage: 5 })
      assert_equal 0, response[:position]
      assert_equal 2, response[:page]

      response = @index.search('elon', { clickAnalytics: true })

      refute_nil response[:queryID]

      response = @index.search('elon', { facets: '*', facetFilters: ['company:tesla'] })

      assert_equal 1, response[:nbHits]

      response = @index.search('elon', { facets: '*', filters: '(company:tesla OR company:spacex)' })

      assert_equal 2, response[:nbHits]

      response = @index.search_for_facet_values('company', 'a')

      assert(response[:facetHits].any? { |hit| hit[:value] == 'Algolia' })
      assert(response[:facetHits].any? { |hit| hit[:value] == 'Amazon' })
      assert(response[:facetHits].any? { |hit| hit[:value] == 'Apple' })
      assert(response[:facetHits].any? { |hit| hit[:value] == 'Arista Networks' })
    end
  end

  describe 'synonyms' do
    def before_all
      super
      @index = @@search_client.init_index(get_test_index_name('synonyms'))
    end

    def test_synonyms
      responses = Algolia::MultipleResponse.new
      responses.push(@index.save_objects([
        { console: 'Sony PlayStation <PLAYSTATIONVERSION>' },
        { console: 'Nintendo Switch' },
        { console: 'Nintendo Wii U' },
        { console: 'Nintendo Game Boy Advance' },
        { console: 'Microsoft Xbox' },
        { console: 'Microsoft Xbox 360' },
        { console: 'Microsoft Xbox One' }
      ], { auto_generate_object_id_if_not_exist: true }))

      synonym1 = {
        objectID: 'gba',
        type: 'synonym',
        synonyms: ['gba', 'gameboy advance', 'game boy advance']
      }

      responses.push(@index.save_synonym(synonym1))

      synonym2 = {
        objectID: 'wii_to_wii_u',
        type: 'onewaysynonym',
        input: 'wii',
        synonyms: ['wii U']
      }

      synonym3 = {
        objectID: 'playstation_version_placeholder',
        type: 'placeholder',
        placeholder: '<PLAYSTATIONVERSION>',
        replacements: ['1', 'One', '2', '3', '4', '4 Pro']
      }

      synonym4 = {
        objectID: 'ps4',
        type: 'altcorrection1',
        word: 'ps4',
        corrections: ['playstation4']
      }

      synonym5 = {
        objectID: 'psone',
        type: 'altcorrection2',
        word: 'psone',
        corrections: ['playstationone']
      }

      responses.push(@index.save_synonyms([synonym2, synonym3, synonym4, synonym5]))

      responses.wait

      assert_equal synonym1, @index.get_synonym(synonym1[:objectID])
      assert_equal synonym2, @index.get_synonym(synonym2[:objectID])
      assert_equal synonym3, @index.get_synonym(synonym3[:objectID])
      assert_equal synonym4, @index.get_synonym(synonym4[:objectID])
      assert_equal synonym5, @index.get_synonym(synonym5[:objectID])

      res = @index.search_synonyms('')
      assert_equal 5, res[:hits].length

      results = []
      @index.browse_synonyms do |synonym|
        results.push(synonym)
      end

      synonyms = [
        synonym1,
        synonym2,
        synonym3,
        synonym4,
        synonym5
      ]

      synonyms.each do |synonym|
        assert_includes results, synonym
      end

      @index.delete_synonym!('gba')

      exception = assert_raises Algolia::AlgoliaHttpError do
        @index.get_synonym('gba')
      end

      assert_equal 'Synonym set does not exist', exception.message

      @index.clear_synonyms!

      res = @index.search_synonyms('')
      assert_equal 0, res[:nbHits]
    end

    describe 'query rules' do
      def before_all
        super
        @index = @@search_client.init_index(get_test_index_name('rules'))
      end

      def test_rules
        responses = Algolia::MultipleResponse.new
        responses.push(@index.save_objects([
          { objectID: 'iphone_7', brand: 'Apple', model: '7' },
          { objectID: 'iphone_8', brand: 'Apple', model: '8' },
          { objectID: 'iphone_x', brand: 'Apple', model: 'X' },
          { objectID: 'one_plus_one', brand: 'OnePlus',
            model: 'One' },
          { objectID: 'one_plus_two', brand: 'OnePlus',
            model: 'Two' }
        ], { auto_generate_object_id_if_not_exist: true }))

        responses.push(@index.set_settings({ attributesForFaceting: %w(brand model) }))

        rule1 = {
          objectID: 'brand_automatic_faceting',
          enabled: false,
          condition: { anchoring: 'is', pattern: '{facet:brand}' },
          consequence: {
            params: {
              automaticFacetFilters: [
                { facet: 'brand', disjunctive: true, score: 42 }
              ]
            }
          },
          validity: [
            {
              from: 1532439300, # 07/24/2018 13:35:00 UTC
              until: 1532525700 # 07/25/2018 13:35:00 UTC
            },
            {
              from: 1532612100, # 07/26/2018 13:35:00 UTC
              until: 1532698500 # 07/27/2018 13:35:00 UTC
            }
          ],
          description: 'Automatic apply the faceting on `brand` if a brand value is found in the query'
        }

        responses.push(@index.save_rule(rule1))

        rule2 = {
          objectID: 'query_edits',
          conditions: [{ anchoring: 'is', pattern: 'mobile phone', alternatives: true }],
          consequence: {
            filterPromotes: false,
            params: {
              query: {
                edits: [
                  { type: 'remove', delete: 'mobile' },
                  { type: 'replace', delete: 'phone', insert: 'iphone' }
                ]
              }
            }
          }
        }

        rule3 = {
          objectID: 'query_promo',
          consequence: {
            params: {
              filters: 'brand:OnePlus'
            }
          }
        }

        rule4 = {
          objectID: 'query_promo_summer',
          condition: {
            context: 'summer'
          },
          consequence: {
            params: {
              filters: 'model:One'
            }
          }
        }

        responses.push(@index.save_rules([rule2, rule3, rule4]))

        responses.wait

        assert_equal 1, @index.search('', { ruleContexts: ['summer'] })[:nbHits]

        assert_equal rule1, rule_without_metadata(@index.get_rule(rule1[:objectID]))
        assert_equal rule2, rule_without_metadata(@index.get_rule(rule2[:objectID]))
        assert_equal rule3, rule_without_metadata(@index.get_rule(rule3[:objectID]))
        assert_equal rule4, rule_without_metadata(@index.get_rule(rule4[:objectID]))

        assert_equal 4, @index.search_rules('')[:nbHits]

        results = []
        @index.browse_rules do |rule|
          results.push(rule)
        end

        rules = [
          rule1,
          rule2,
          rule3,
          rule4
        ]

        results.each do |rule|
          assert_includes rules, rule_without_metadata(rule)
        end

        @index.delete_rule!(rule1[:objectID])

        exception = assert_raises Algolia::AlgoliaHttpError do
          @index.get_rule(rule1[:objectID])
        end

        assert_equal 'ObjectID does not exist', exception.message

        @index.clear_rules!

        res = @index.search_rules('')
        assert_equal 0, res[:nbHits]
      end
    end

    describe 'batching' do
      def before_all
        super
        @index = @@search_client.init_index(get_test_index_name('index_batching'))
      end

      def test_index_batching
        @index.save_objects!([
          { objectID: 'one', key: 'value' },
          { objectID: 'two', key: 'value' },
          { objectID: 'three', key: 'value' },
          { objectID: 'four', key: 'value' },
          { objectID: 'five', key: 'value' }
        ])

        @index.batch!([
          { action: 'addObject', body: { objectID: 'zero', key: 'value' } },
          { action: 'updateObject', body: { objectID: 'one', k: 'v' } },
          { action: 'partialUpdateObject', body: { objectID: 'two', k: 'v' } },
          { action: 'partialUpdateObject', body: { objectID: 'two_bis', key: 'value' } },
          { action: 'partialUpdateObjectNoCreate', body: { objectID: 'three', k: 'v' } },
          { action: 'deleteObject', body: { objectID: 'four' } }
        ])

        objects = [
          { objectID: 'zero', key: 'value' },
          { objectID: 'one', k: 'v' },
          { objectID: 'two', key: 'value', k: 'v' },
          { objectID: 'two_bis', key: 'value' },
          { objectID: 'three', key: 'value', k: 'v' },
          { objectID: 'five', key: 'value' }
        ]

        @index.browse_objects do |object|
          assert_includes objects, object
        end
      end
    end

    describe 'replacing' do
      def before_all
        super
        @index = @@search_client.init_index(get_test_index_name('replacing'))
      end

      def test_replacing
        responses = Algolia::MultipleResponse.new
        responses.push(@index.save_object({ objectID: 'one' }))
        responses.push(@index.save_rule({
          objectID: 'one',
          condition: { anchoring: 'is', pattern: 'pattern' },
          consequence: {
            params: {
              query: {
                edits: [
                  { type: 'remove', delete: 'pattern' }
                ]
              }
            }
          }
        }))
        responses.push(@index.save_synonym({ objectID: 'one', type: 'synonym', synonyms: %w(one two) }))
        responses.wait

        @index.replace_all_objects!([{ objectID: 'two' }])
        responses.push(@index.replace_all_rules([{
          objectID: 'two',
          condition: { anchoring: 'is', pattern: 'pattern' },
          consequence: {
            params: {
              query: {
                edits: [
                  { type: 'remove', delete: 'pattern' }
                ]
              }
            }
          }
        }]))

        responses.push(@index.replace_all_synonyms([{ objectID: 'two', type: 'synonym', synonyms: %w(one two) }]))

        responses.wait

        exception = assert_raises Algolia::AlgoliaHttpError do
          @index.get_object('one')
        end

        assert_equal 'ObjectID does not exist', exception.message

        assert_equal 'two', @index.get_object('two')[:objectID]

        exception = assert_raises Algolia::AlgoliaHttpError do
          @index.get_rule('one')
        end

        assert_equal 'ObjectID does not exist', exception.message

        assert_equal 'two', @index.get_rule('two')[:objectID]

        exception = assert_raises Algolia::AlgoliaHttpError do
          @index.get_synonym('one')
        end

        assert_equal 'Synonym set does not exist', exception.message

        assert_equal 'two', @index.get_synonym('two')[:objectID]
      end
    end

    describe 'exists' do
      def before_all
        super
        @index = @@search_client.init_index(get_test_index_name('exists'))
      end

      def test_exists
        refute @index.exists?
        @index.save_object!(generate_object('111'))
        assert @index.exists?
        @index.delete!
        refute @index.exists?
      end
    end
  end
end
