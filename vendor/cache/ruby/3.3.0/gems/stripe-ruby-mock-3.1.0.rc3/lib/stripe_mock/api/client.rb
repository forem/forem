module StripeMock

  def self.client
    @client
  end

  def self.start_client(port=4999)
    return false if @state == 'live'
    return @client unless @client.nil?

    Stripe::StripeClient.send(:define_method, :execute_request) { |*args, **keyword_args| StripeMock.redirect_to_mock_server(*args, **keyword_args) }
    @client = StripeMock::Client.new(port)
    @state = 'remote'
    @client
  end

  def self.stop_client(opts={})
    return false unless @state == 'remote'
    @state = 'ready'

    restore_stripe_execute_request_method
    @client.clear_server_data if opts[:clear_server_data] == true
    @client.cleanup
    @client = nil
    true
  end

  private

  def self.redirect_to_mock_server(method, url, api_key: nil, api_base: nil, params: {}, headers: {})
    handler = Instance.handler_for_method_url("#{method} #{url}")

    if mock_error = client.error_queue.error_for_handler_name(handler[:name])
      client.error_queue.dequeue
      raise mock_error
    end

    Stripe::Util.symbolize_names client.mock_request(method, url, api_key: api_key, params: params, headers: headers)
  end

end
