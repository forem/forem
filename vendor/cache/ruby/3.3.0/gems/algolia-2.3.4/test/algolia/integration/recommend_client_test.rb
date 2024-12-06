require 'securerandom'
require_relative 'base_test'

class RecommendClientTest < BaseTest
  describe 'Recommendations' do
    def test_get_recommendations
      requester = MockRequester.new
      client    = Algolia::Recommend::Client.new(@@search_config, http_requester: requester)

      # It correctly formats queries using the 'bought-together' model
      client.get_recommendations([{ indexName: 'products', objectID: 'B018APC4LE', model: Algolia::Recommend::Model::BOUGHT_TOGETHER }])

      # It correctly formats queries using the 'related-products' model
      client.get_recommendations([{ indexName: 'products', objectID: 'B018APC4LE', model: Algolia::Recommend::Model::RELATED_PRODUCTS }])

      # It correctly formats multiple queries.
      client.get_recommendations(
        [
          { indexName: 'products', objectID: 'B018APC4LE-1', model: Algolia::Recommend::Model::RELATED_PRODUCTS, threshold: 0 },
          { indexName: 'products', objectID: 'B018APC4LE-2', model: Algolia::Recommend::Model::RELATED_PRODUCTS, threshold: 0 }
        ]
      )

      # It resets the threshold to 0 if it's not numeric.
      client.get_recommendations([{ indexName: 'products', objectID: 'B018APC4LE', model: Algolia::Recommend::Model::BOUGHT_TOGETHER, threshold: nil }])

      # It passes the threshold correctly if it's numeric.
      client.get_recommendations([{ indexName: 'products', objectID: 'B018APC4LE', model: Algolia::Recommend::Model::BOUGHT_TOGETHER, threshold: 42 }])

      assert_requests(
        requester,
        [
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"bought-together","threshold":0}]}' },
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"related-products","threshold":0}]}' },
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE-1","model":"related-products","threshold":0},{"indexName":"products","objectID":"B018APC4LE-2","model":"related-products","threshold":0}]}' },
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"bought-together","threshold":0}]}' },
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"bought-together","threshold":42}]}' }
        ]
      )
    end

    def test_get_related_products
      requester = MockRequester.new
      client    = Algolia::Recommend::Client.new(@@search_config, http_requester: requester)

      client.get_related_products([{ indexName: 'products', objectID: 'B018APC4LE' }])

      assert_requests(
        requester,
        [{ method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"related-products","threshold":0}]}' }]
      )
    end

    def test_get_frequently_bought_together
      requester = MockRequester.new
      client    = Algolia::Recommend::Client.new(@@search_config, http_requester: requester)

      client.get_frequently_bought_together([{ indexName: 'products', objectID: 'B018APC4LE' }])
      client.get_frequently_bought_together([{ indexName: 'products', objectID: 'B018APC4LE', fallbackParameters: {} }])

      assert_requests(
        requester,
        [
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"bought-together","threshold":0}]}' },
          { method: :post, path: '/1/indexes/*/recommendations', body: '{"requests":[{"indexName":"products","objectID":"B018APC4LE","model":"bought-together","threshold":0}]}' }
        ]
      )
    end
  end
end
