require_relative 'base_test'

class AccountClientTest < BaseTest
  describe 'Account client' do
    def test_account_client
      index1 = @@search_client.init_index(get_test_index_name('copy_index'))
      index2 = @@search_client.init_index(get_test_index_name('copy_index2'))

      exception = assert_raises Algolia::AlgoliaError do
        Algolia::Account::Client.copy_index(index1, index2)
      end

      assert_equal 'The indices are on the same application. Use Algolia::Search::Client.copy_index instead.', exception.message

      search_client2 = Algolia::Search::Client.create(APPLICATION_ID_2, ADMIN_KEY_2)
      index2         = search_client2.init_index(get_test_index_name('copy_index2'))
      index1.save_object!({ objectID: 'one', title: 'Test title' })
      index1.save_rule!({
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
      })
      index1.save_synonym!({ objectID: 'one', type: 'synonym', synonyms: %w(one two) })
      index1.set_settings!({ searchableAttributes: ['title'] })

      Algolia::Account::Client.copy_index!(index1, index2)
      assert_equal 'one', index2.get_object('one')[:objectID]
      assert_equal 'one', index2.get_synonym('one')[:objectID]
      assert_equal 'one', index2.get_rule('one')[:objectID]
      assert index2.get_settings[:searchableAttributes]

      exception = assert_raises Algolia::AlgoliaError do
        Algolia::Account::Client.copy_index(index1, index2)
      end

      assert_equal 'Destination index already exists. Please delete it before copying index across applications.', exception.message
    end
  end
end
