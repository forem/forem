require 'algolia'
require 'test_helper'

class HttpRequesterTest
  describe 'connection' do
    def test_caches_http_client_connections
      requester = Algolia::Http::HttpRequester.new(Defaults::ADAPTER, nil)
      host1     = Algolia::Transport::StatefulHost.new('host1')

      # rubocop:disable Lint/UselessComparison
      assert requester.connection(host1) == requester.connection(host1)
      # rubocop:enable Lint/UselessComparison
      assert_equal requester.connection(host1).url_prefix.host, 'host1'
    end

    def test_caches_hosts_independent_of_each_other
      requester = Algolia::Http::HttpRequester.new(Defaults::ADAPTER, nil)
      host1     = Algolia::Transport::StatefulHost.new('host1')
      host2     = Algolia::Transport::StatefulHost.new('host2')

      assert requester.connection(host1) != requester.connection(host2)

      assert_equal requester.connection(host1).url_prefix.host, 'host1'
      assert_equal requester.connection(host2).url_prefix.host, 'host2'
    end
  end
end
