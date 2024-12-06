require_relative 'base_test'
require 'date'

class InsightsClientTest < BaseTest
  describe 'Insights client' do
    def test_insights_client
      index  = @@search_client.init_index(get_test_index_name('sending_events'))
      client = Algolia::Insights::Client.create(APPLICATION_ID_1, ADMIN_KEY_1)

      index.save_objects!([
        { objectID: 'one' },
        { objectID: 'two' }
      ])

      today = Date.today

      client.send_event({
        eventType: 'click',
        eventName: 'foo',
        index: index.name,
        userToken: 'bar',
        objectIDs: %w(one two),
        timestamp: (today - 2).strftime('%Q').to_i
      })

      client.send_events([
        {
          eventType: 'click',
          eventName: 'foo',
          index: index.name,
          userToken: 'bar',
          objectIDs: %w(one two),
          timestamp: (today - 2).strftime('%Q').to_i
        }, {
          eventType: 'click',
          eventName: 'foo',
          index: index.name,
          userToken: 'bar',
          objectIDs: %w(one two),
          timestamp: (today - 2).strftime('%Q').to_i
        }
      ])

      user_client = client.user('bar')
      response    = user_client.clicked_object_ids('foo', index.name, %w(one two))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      query_id = index.search('', { clickAnalytics: true })[:queryID]

      response = user_client.clicked_object_ids_after_search('foo', index.name, %w(one two), [1, 2], query_id)
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.clicked_filters('foo', index.name, %w(filter:foo filter:bar))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.converted_object_ids('foo', index.name, %w(one two))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.converted_object_ids_after_search('foo', index.name, %w(one two), query_id)
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.converted_filters('foo', index.name, %w(filter:foo filter:bar))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.viewed_object_ids('foo', index.name, %w(one two))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]

      response = user_client.viewed_filters('foo', index.name, %w(filter:foo filter:bar))
      assert_equal 200, response[:status]
      assert_equal 'OK', response[:message]
    end
  end
end
