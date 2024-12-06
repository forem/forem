require_relative 'base_test'
require 'date'

class PersonalizationClientTest < BaseTest
  describe 'Personalization client' do
    def test_personalization_client
      client                   = Algolia::Personalization::Client.create(APPLICATION_ID_1, ADMIN_KEY_1)
      personalization_strategy = {
        eventsScoring: [
          { eventName: 'Add to cart', eventType: 'conversion', score: 50 },
          { eventName: 'Purchase', eventType: 'conversion', score: 100 }
        ],
        facetsScoring: [
          { facetName: 'brand', score: 100 },
          { facetName: 'categories', score: 10 }
        ],
        personalizationImpact: 0
      }

      begin
        client.set_personalization_strategy(personalization_strategy)
      rescue Algolia::AlgoliaHttpError => e
        raise e unless e.code == 429
      end
      response = client.get_personalization_strategy

      assert_equal response, personalization_strategy
    end
  end
end
