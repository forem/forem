require_relative '../test_helper'

describe Fastly::Token do
  let(:fastly) { Fastly.new(api_key:'my_api_key', user: 'test@example.com', password: 'password') }

  before {
    stub_request(:post, "#{Fastly::Client::DEFAULT_URL}/login").to_return(body: '{}', status: 200)
  }

  describe '#fastly' do
    it 'cannot create itself because POST /tokens must have no auth headers' do
      stub_request(:post, "https://api.fastly.com/tokens").
      with(
        body: {"name"=>"name_of_token", "scope"=>"token_scope such_as purge_all purge_select", "services"=>"service_id_that_token_can_access"},
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Accept'=>'application/json',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent'=> /fastly-ruby/
        }).
      to_return(status: 403, body: '{"msg":"You must POST /sudo to access this endpoint"}', headers: {})

      assert_raises(Fastly::Error,'{"msg":"You must POST /sudo to access this endpoint"}') do
        fastly.create_token(
          name: 'name_of_token',
          services: 'service_id_that_token_can_access',
          scope: 'token_scope such_as purge_all purge_select'
        )
      end
    end
    
    it 'can create a new token only if there are no auth headers' do
      response_body = %q(
        {
          "id": "5Yo3XXnrQpjc20u0ybrf2g",
          "access_token": "YOUR_FASTLY_TOKEN",
          "user_id": "4y5K5trZocEAQYkesWlk7M",
          "services": ["service_id_that_token_can_access"],
          "name": "name_of_token",
          "scope": "optional token_scope such_as purge_all purge_select",
          "created_at": "2016-06-22T03:19:48+00:00",
          "last_used_at": "2016-06-22T03:19:48+00:00",
          "expires_at": "2016-07-28T19:24:50+00:00",
          "ip": "127.17.202.173",
          "user_agent": "fastly-ruby-v2.4.0"
        }
      )

      stub_request(:post, "https://api.fastly.com/tokens").
      with(
        body: {"name"=>"name_of_token", "password"=>"password", "scope"=>"optional token_scope such_as purge_all purge_select", "services"=>"service_id_that_token_can_access", "username"=>"test@example.com"},
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Accept'=>'application/json',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent'=> /fastly-ruby/
        }).
      to_return(status: 200, body: response_body, headers: {})

      token = fastly.new_token(
        name: 'name_of_token',
        services: 'service_id_that_token_can_access',
        scope: 'optional token_scope such_as purge_all purge_select'
      )
      assert_equal token.id, '5Yo3XXnrQpjc20u0ybrf2g'
      assert_equal token.user_id, '4y5K5trZocEAQYkesWlk7M'
      assert_equal token.services[0], 'service_id_that_token_can_access'
      assert_equal token.name, 'name_of_token'
      assert_equal token.scope, 'optional token_scope such_as purge_all purge_select'
      assert_equal token.created_at, '2016-06-22T03:19:48+00:00'
      assert_equal token.last_used_at, '2016-06-22T03:19:48+00:00'
      assert_equal token.expires_at, '2016-07-28T19:24:50+00:00'
      assert_equal token.ip, '127.17.202.173'
      assert_equal token.user_agent, 'fastly-ruby-v2.4.0'
      assert_equal token.access_token, 'YOUR_FASTLY_TOKEN'
    end
    
    it 'would delete a token' do
      stub_request(:delete, "https://api.fastly.com/tokens/").
      with(
        headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Accept'=>'application/json',
        'Fastly-Key'=>'my_api_key',
        'User-Agent'=> /fastly-ruby/
        }).
      to_return(status: 204, body: "", headers: {})

      token = Fastly::Token.new({acess_token: 'my_api_key'}, Fastly::Fetcher)  
      fastly.delete_token(token) 
    end

    it 'would list all the tokens belonging to a token' do
      stub_request(:get, "https://api.fastly.com/tokens").
        with(
          headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Accept'=>'application/json',
          'Fastly-Key'=>'my_api_key',
          'User-Agent'=> /fastly-ruby/
          }).
        to_return(status: 200, body: "[]", headers: {})

      fastly.list_tokens()
    end

    it 'would list all the tokens belonging to a customer' do
      stub_request(:get, "https://api.fastly.com/customer/customer_account_number/tokens").
        with(
          headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Accept'=>'application/json',
          'Fastly-Key'=>'my_api_key',
          'User-Agent'=> /fastly-ruby/
          }).
        to_return(status: 200, body: "[]", headers: {})

      fastly.customer_tokens({customer_id: 'customer_account_number'})
    end

  end
end
