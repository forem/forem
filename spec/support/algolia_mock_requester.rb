# from https://github.com/algolia/algoliasearch-client-ruby/blob/master/test/algolia/integration/mocks/mock_requester.rb
class AlgoliaMockRequester
  attr_accessor :requests

  def initialize
    @connection = nil
    @requests   = []
  end

  def send_request(host, method, path, body, headers, timeout, connect_timeout)
    request = {
      host: host,
      method: method,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
      connect_timeout: connect_timeout
    }

    @requests.push(request)

    Algolia::Http::Response.new(
      status: 200,
      body: '{"hits": [], "status": "published"}',
      headers: {},
    )
  end

  def get_connection(host)
    @connection = host
  end

  def build_url(host)
    host.protocol + host.url
  end
end
