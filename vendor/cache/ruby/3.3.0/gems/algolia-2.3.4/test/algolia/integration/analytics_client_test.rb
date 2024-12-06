require_relative 'base_test'
require 'date'

class AnalyticsClientTest < BaseTest
  describe 'Analytics client' do
    def test_ab_testing
      index1 = @@search_client.init_index(get_test_index_name('ab_testing'))
      index2 = @@search_client.init_index(get_test_index_name('ab_testing_dev'))
      client = Algolia::Analytics::Client.create(APPLICATION_ID_1, ADMIN_KEY_1)

      index1.save_object!({ objectID: 'one' })
      index2.save_object!({ objectID: 'one' })

      ab_test_name = index1.name
      tomorrow     = Time.now + 24*60*60

      ab_test = {
        name: ab_test_name,
        variants: [
          { index: index1.name, trafficPercentage: 60, description: 'a description' },
          { index: index2.name, trafficPercentage: 40 }
        ],
        endAt: tomorrow.strftime('%Y-%m-%dT%H:%M:%SZ')
      }

      response   = retry_test do
        client.add_ab_test(ab_test)
      end
      ab_test_id = response[:abTestID]

      index1.wait_task(response[:taskID])
      result = client.get_ab_test(ab_test_id)

      assert_equal ab_test[:name], result[:name]
      assert_equal ab_test[:variants][0][:index], result[:variants][0][:index]
      assert_equal ab_test[:variants][0][:trafficPercentage], result[:variants][0][:trafficPercentage]
      assert_equal ab_test[:variants][0][:description], result[:variants][0][:description]
      assert_equal ab_test[:endAt], result[:endAt]
      refute_equal 'stopped', result[:status]

      ab_tests = client.get_ab_tests
      found    = false
      ab_tests[:abtests].each do |iterated_ab_test|
        if iterated_ab_test[:name] == ab_test_name
          assert_equal ab_test[:name], iterated_ab_test[:name]
          assert_equal ab_test[:variants][0][:index], iterated_ab_test[:variants][0][:index]
          assert_equal ab_test[:variants][0][:trafficPercentage], iterated_ab_test[:variants][0][:trafficPercentage]
          assert_equal ab_test[:variants][0][:description], iterated_ab_test[:variants][0][:description]
          assert_equal ab_test[:endAt], iterated_ab_test[:endAt]
          refute_equal 'stopped', iterated_ab_test[:status]
          found = true
        end
      end

      assert found

      response = client.stop_ab_test(ab_test_id)
      index1.wait_task(response[:taskID])
      result   = client.get_ab_test(ab_test_id)
      assert_equal 'stopped', result[:status]

      response = client.delete_ab_test(ab_test_id)
      index1.wait_task(response[:taskID])

      exception = assert_raises Algolia::AlgoliaHttpError do
        client.get_ab_test(ab_test_id)
      end

      assert_equal 404, exception.code
      assert_equal 'ABTestID not found', exception.message
    end

    def test_aa_testing
      index  = @@search_client.init_index(get_test_index_name('aa_testing'))
      client = Algolia::Analytics::Client.create(APPLICATION_ID_1, ADMIN_KEY_1)

      index.save_object!({ objectID: 'one' })

      ab_test_name = index.name
      tomorrow     = Time.now + 24*60*60

      ab_test = {
        name: ab_test_name,
        variants: [
          { index: index.name, trafficPercentage: 90 },
          { index: index.name, trafficPercentage: 10, customSearchParameters: { ignorePlurals: true } }
        ],
        endAt: tomorrow.strftime('%Y-%m-%dT%H:%M:%SZ')
      }

      response   = retry_test do
        client.add_ab_test(ab_test)
      end
      ab_test_id = response[:abTestID]

      index.wait_task(response[:taskID])
      result = client.get_ab_test(ab_test_id)

      assert_equal ab_test[:name], result[:name]
      assert_equal ab_test[:variants][0][:index], result[:variants][0][:index]
      assert_equal ab_test[:variants][0][:trafficPercentage], result[:variants][0][:trafficPercentage]
      assert_equal ab_test[:variants][1][:customSearchParameters], result[:variants][1][:customSearchParameters]
      assert_equal ab_test[:endAt], result[:endAt]
      refute_equal 'stopped', result[:status]

      response = client.delete_ab_test(ab_test_id)
      index.wait_task(response[:taskID])

      exception = assert_raises Algolia::AlgoliaHttpError do
        client.get_ab_test(ab_test_id)
      end

      assert_equal 404, exception.code
      assert_equal 'ABTestID not found', exception.message
    end
  end
end
