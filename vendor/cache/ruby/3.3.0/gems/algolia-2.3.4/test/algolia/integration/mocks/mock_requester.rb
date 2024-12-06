class MockRequester
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
      headers: {}
    )
  end

  # Retrieve the connection from the @connections
  #
  # @param host [StatefulHost]
  #
  # @return [Faraday::Connection]
  #
  def get_connection(host)
    @connection = host
  end

  # Build url from host, path and parameters
  #
  # @param host [StatefulHost]
  #
  # @return [String]
  #
  def build_url(host)
    host.protocol + host.url
  end
end
