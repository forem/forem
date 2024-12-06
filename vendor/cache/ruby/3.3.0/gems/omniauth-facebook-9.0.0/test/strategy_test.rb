require 'helper'
require 'omniauth-facebook'
require 'openssl'
require 'base64'

class StrategyTest < StrategyTestCase
  include OAuth2StrategyTests
end

class ClientTest < StrategyTestCase
  test 'has correct Facebook site' do
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}", strategy.client.site
  end

  test 'has correct authorize url' do
    assert_equal "https://www.facebook.com/#{@facebook_api_version}/dialog/oauth", strategy.client.options[:authorize_url]
  end

  test 'has correct token url with versioning' do
    @options = {client_options: {site: 'https://graph.facebook.net/v2.2'}}
    assert_equal 'oauth/access_token', strategy.client.options[:token_url]
    assert_equal 'https://graph.facebook.net/v2.2/oauth/access_token', strategy.client.token_url
  end
end

class CallbackUrlTest < StrategyTestCase
  test "returns the default callback url (omitting querystring)" do
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/some/page")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    strategy.stubs(:query_string).returns('?foo=bar')
    assert_equal "#{url_base}/auth/facebook/callback", strategy.callback_url
  end

  test "returns path from callback_path option (omitting querystring)" do
    @options = { callback_path: "/auth/FB/done"}
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/page/path")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    strategy.stubs(:query_string).returns('?foo=bar')
    assert_equal "#{url_base}/auth/FB/done", strategy.callback_url
  end

  test "returns url from callback_url option" do
    url = 'https://auth.myapp.com/auth/fb/callback'
    @options = { callback_url: url }
    assert_equal url, strategy.callback_url
  end
end

class AuthorizeParamsTest < StrategyTestCase
  test 'includes default scope for email' do
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'email', strategy.authorize_params[:scope]
  end

  test 'includes display parameter from request when present' do
    @request.stubs(:params).returns({ 'display' => 'touch' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'touch', strategy.authorize_params[:display]
  end

  test 'includes auth_type parameter from request when present' do
    @request.stubs(:params).returns({ 'auth_type' => 'reauthenticate' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'reauthenticate', strategy.authorize_params[:auth_type]
  end

  test 'overrides default scope with parameter passed from request' do
    @request.stubs(:params).returns({ 'scope' => 'email' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'email', strategy.authorize_params[:scope]
  end
end

class AccessTokenOptionsTest < StrategyTestCase
  test 'has correct param name by default' do
    assert_equal 'access_token', strategy.access_token_options[:param_name]
  end

  test 'has correct header format by default' do
    assert_equal 'OAuth %s', strategy.access_token_options[:header_format]
  end
end

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'id' => '123' })
  end

  test 'returns the id from raw_info' do
    assert_equal '123', strategy.uid
  end
end

class InfoTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @access_token.stubs(:token).returns('test_access_token')
  end

  test 'returns the secure facebook avatar url when `secure_image_url` option is set to true' do
    @options = { secure_image_url: true }
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token", strategy.info['image']
  end

  test 'returns the non-ssl facebook avatar url when `secure_image_url` option is set to false' do
    @options = { secure_image_url: false }
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "http://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token", strategy.info['image']
  end

  test 'returns the secure facebook avatar url when `secure_image_url` option is omitted' do
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token", strategy.info['image']
  end

  test 'returns the image_url based of the client site' do
    @options = { secure_image_url: true, client_options: {site: "https://blah.facebook.com/v2.2"}}
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "https://blah.facebook.com/v2.2/321/picture?access_token=test_access_token", strategy.info['image']
  end

  test 'returns the image with size specified in the `image_size` option' do
    @options = { image_size: 'normal' }
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token&type=normal", strategy.info['image']
  end

  test 'returns the image with size specified as a symbol in the `image_size` option' do
    @options = { image_size: :normal }
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token&type=normal", strategy.info['image']
  end

  test 'returns the image with width and height specified in the `image_size` option' do
    @options = { image_size: { width: 123, height: 987 } }
    raw_info = { 'name' => 'Fred Smith', 'id' => '321' }
    strategy.stubs(:raw_info).returns(raw_info)
    strategy.stubs(:access_token).returns(@access_token)
    assert_match 'width=123', strategy.info['image']
    assert_match 'height=987', strategy.info['image']
    assert_match "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token", strategy.info['image']
  end
end

class InfoTestOptionalDataPresent < StrategyTestCase
  def setup
    super
    @raw_info ||= { 'name' => 'Fred Smith' }
    strategy.stubs(:raw_info).returns(@raw_info)

    access_token = stub('OAuth2::AccessToken')
    access_token.stubs(:token).returns('test_access_token')
    strategy.stubs(:access_token).returns(access_token)
  end

  test 'returns the name' do
    assert_equal 'Fred Smith', strategy.info['name']
  end

  test 'returns the email' do
    @raw_info['email'] = 'fred@smith.com'
    assert_equal 'fred@smith.com', strategy.info['email']
  end

  test 'returns the username as nickname' do
    @raw_info['username'] = 'fredsmith'
    assert_equal 'fredsmith', strategy.info['nickname']
  end

  test 'returns the first name' do
    @raw_info['first_name'] = 'Fred'
    assert_equal 'Fred', strategy.info['first_name']
  end

  test 'returns the last name' do
    @raw_info['last_name'] = 'Smith'
    assert_equal 'Smith', strategy.info['last_name']
  end

  test 'returns the location name as location' do
    @raw_info['location'] = { 'id' => '104022926303756', 'name' => 'Palo Alto, California' }
    assert_equal 'Palo Alto, California', strategy.info['location']
  end

  test 'returns bio as description' do
    @raw_info['bio'] = 'I am great'
    assert_equal 'I am great', strategy.info['description']
  end

  test 'returns the facebook avatar url' do
    @raw_info['id'] = '321'
    assert_equal "https://graph.facebook.com/#{@facebook_api_version}/321/picture?access_token=test_access_token", strategy.info['image']
  end

  test 'returns the Facebook link as the Facebook url' do
    @raw_info['link'] = 'http://www.facebook.com/fredsmith'
    assert_kind_of Hash, strategy.info['urls']
    assert_equal 'http://www.facebook.com/fredsmith', strategy.info['urls']['Facebook']
  end

  test 'returns website url' do
    @raw_info['website'] = 'https://my-wonderful-site.com'
    assert_kind_of Hash, strategy.info['urls']
    assert_equal 'https://my-wonderful-site.com', strategy.info['urls']['Website']
  end

  test 'return both Facebook link and website urls' do
    @raw_info['link'] = 'http://www.facebook.com/fredsmith'
    @raw_info['website'] = 'https://my-wonderful-site.com'
    assert_kind_of Hash, strategy.info['urls']
    assert_equal 'http://www.facebook.com/fredsmith', strategy.info['urls']['Facebook']
    assert_equal 'https://my-wonderful-site.com', strategy.info['urls']['Website']
  end

  test 'returns the positive verified status' do
    @raw_info['verified'] = true
    assert strategy.info['verified']
  end

  test 'returns the negative verified status' do
    @raw_info['verified'] = false
    refute strategy.info['verified']
  end
end

class InfoTestOptionalDataNotPresent < StrategyTestCase
  def setup
    super
    @raw_info ||= { 'name' => 'Fred Smith' }
    strategy.stubs(:raw_info).returns(@raw_info)

    access_token = stub('OAuth2::AccessToken')
    access_token.stubs(:token).returns('test_access_token')
    strategy.stubs(:access_token).returns(access_token)
  end

  test 'has no email key' do
    refute_has_key 'email', strategy.info
  end

  test 'has no nickname key' do
    refute_has_key 'nickname', strategy.info
  end

  test 'has no first name key' do
    refute_has_key 'first_name', strategy.info
  end

  test 'has no last name key' do
    refute_has_key 'last_name', strategy.info
  end

  test 'has no location key' do
    refute_has_key 'location', strategy.info
  end

  test 'has no description key' do
    refute_has_key 'description', strategy.info
  end

  test 'has no urls' do
    refute_has_key 'urls', strategy.info
  end

  test 'has no verified key' do
    refute_has_key 'verified', strategy.info
  end
end

class RawInfoTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @appsecret_proof = 'appsecret_proof'
    @options = {appsecret_proof: @appsecret_proof, fields: 'name,email'}
  end

  test "performs a GET to https://graph.facebook.com/#{@facebook_api_version}/me" do
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    strategy.stubs(:access_token).returns(@access_token)
    params = {params: @options}
    @access_token.expects(:get).with('me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test "performs a GET to https://graph.facebook.com/#{@facebook_api_version}/me with locale" do
    @options.merge!({ locale: 'cs_CZ' })
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    params = {params: @options}
    @access_token.expects(:get).with('me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test "performs a GET to https://graph.facebook.com/#{@facebook_api_version}/me with info_fields" do
    @options.merge!({info_fields: 'about'})
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    params = {params: {appsecret_proof: @appsecret_proof, fields: 'about'}}
    @access_token.expects(:get).with('me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test "performs a GET to https://graph.facebook.com/#{@facebook_api_version}/me with default info_fields" do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    params = {params: {appsecret_proof: @appsecret_proof, fields: 'name,email'}}
    @access_token.expects(:get).with('me', params).returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test 'returns a Hash' do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    raw_response = stub('Faraday::Response')
    raw_response.stubs(:body).returns('{ "ohai": "thar" }')
    raw_response.stubs(:status).returns(200)
    raw_response.stubs(:headers).returns({'Content-Type' => 'application/json' })
    oauth2_response = OAuth2::Response.new(raw_response)
    params = {params: @options}
    @access_token.stubs(:get).with('me', params).returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
    assert_equal 'thar', strategy.raw_info['ohai']
  end

  test 'returns an empty hash when the response is false' do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    oauth2_response = stub('OAuth2::Response', parsed: false)
    params = {params: @options}
    @access_token.stubs(:get).with('me', params).returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
    assert_equal({}, strategy.raw_info)
  end

  test 'should not include raw_info in extras hash when skip_info is specified' do
    @options = { skip_info: true }
    strategy.stubs(:raw_info).returns({foo: 'bar' })
    refute_has_key 'raw_info', strategy.extra
  end
end

class CredentialsTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @access_token.stubs(:token)
    @access_token.stubs(:expires?)
    @access_token.stubs(:expires_at)
    @access_token.stubs(:refresh_token)
    strategy.stubs(:access_token).returns(@access_token)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.credentials
  end

  test 'returns the token' do
    @access_token.stubs(:token).returns('123')
    assert_equal '123', strategy.credentials['token']
  end

  test 'returns the expiry status' do
    @access_token.stubs(:expires?).returns(true)
    assert strategy.credentials['expires']

    @access_token.stubs(:expires?).returns(false)
    refute strategy.credentials['expires']
  end

  test 'returns the refresh token and expiry time when expiring' do
    ten_mins_from_now = (Time.now + 600).to_i
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns('321')
    @access_token.stubs(:expires_at).returns(ten_mins_from_now)
    assert_equal '321', strategy.credentials['refresh_token']
    assert_equal ten_mins_from_now, strategy.credentials['expires_at']
  end

  test 'does not return the refresh token when test is nil and expiring' do
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns(nil)
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end

  test 'does not return the refresh token when not expiring' do
    @access_token.stubs(:expires?).returns(false)
    @access_token.stubs(:refresh_token).returns('XXX')
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end
end

class ExtraTest < StrategyTestCase
  def setup
    super
    @raw_info = { 'name' => 'Fred Smith' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.extra
  end

  test 'contains raw info' do
    assert_equal({ 'raw_info' => @raw_info }, strategy.extra)
  end
end

module SignedRequestHelpers
  def signed_request(payload, secret)
    encoded_payload = base64_encode_url(MultiJson.encode(payload))
    encoded_signature = base64_encode_url(signature(encoded_payload, secret))
    [encoded_signature, encoded_payload].join('.')
  end

  def base64_encode_url(value)
    Base64.encode64(value).tr('+/', '-_').gsub(/\n/, '')
  end

  def signature(payload, secret, algorithm = OpenSSL::Digest::SHA256.new)
    OpenSSL::HMAC.digest(algorithm, secret, payload)
  end
end

module SignedRequestTests
  class TestCase < StrategyTestCase
    include SignedRequestHelpers
  end

  class CookieAndParamNotPresentTest < TestCase
    test 'is nil' do
      assert_nil strategy.send(:signed_request_from_cookie)
    end

    test 'throws an error on calling build_access_token' do
      assert_raises(OmniAuth::Strategies::Facebook::NoAuthorizationCodeError) { strategy.send(:with_authorization_code!) {} }
    end
  end

  class CookiePresentTest < TestCase
    def setup(algo = nil)
      super()
      @payload = {
        'algorithm' => algo || 'HMAC-SHA256',
        'code' => 'm4c0d3z',
        'issued_at' => Time.now.to_i,
        'user_id' => '123456'
      }

      @request.stubs(:cookies).returns({"fbsr_#{@client_id}" => signed_request(@payload, @client_secret)})
    end

    test 'parses the access code out from the cookie' do
      assert_equal @payload, strategy.send(:signed_request_from_cookie)
    end

    test 'throws an error if the algorithm is unknown' do
      setup('UNKNOWN-ALGO')
      assert_equal "unknown algorithm: UNKNOWN-ALGO", assert_raises(OmniAuth::Facebook::SignedRequest::UnknownSignatureAlgorithmError) { strategy.send(:signed_request_from_cookie) }.message
    end
  end

  class EmptySignedRequestTest < TestCase
    def setup
      super
      @request.stubs(:params).returns({'signed_request' => ''})
    end

    test 'empty param' do
      assert_nil strategy.send(:signed_request_from_cookie)
    end
  end

  class MissingCodeInParamsRequestTest < TestCase
    def setup
      super
      @request.stubs(:params).returns({})
    end

    test 'calls fail! when a code is not included in the params' do
      strategy.expects(:fail!).times(1).with(:no_authorization_code, kind_of(OmniAuth::Strategies::Facebook::NoAuthorizationCodeError))
      strategy.callback_phase
    end
  end

  class MissingCodeInCookieRequestTest < TestCase
    def setup(algo = nil)
      super()
      @payload = {
        'algorithm' => algo || 'HMAC-SHA256',
        'code' => nil,
        'issued_at' => Time.now.to_i,
        'user_id' => '123456'
      }

      @request.stubs(:cookies).returns({"fbsr_#{@client_id}" => signed_request(@payload, @client_secret)})
    end

    test 'calls fail! when a code is not included in the cookie' do
      strategy.expects(:fail!).times(1).with(:no_authorization_code, kind_of(OmniAuth::Strategies::Facebook::NoAuthorizationCodeError))
      strategy.callback_phase
    end
  end

  class UnknownAlgorithmInCookieRequestTest < TestCase
    def setup
      super()
      @payload = {
        'algorithm' => 'UNKNOWN-ALGO',
        'code' => nil,
        'issued_at' => Time.now.to_i,
        'user_id' => '123456'
      }

      @request.stubs(:cookies).returns({"fbsr_#{@client_id}" => signed_request(@payload, @client_secret)})
    end

    test 'calls fail! when an algorithm is unknown' do
      strategy.expects(:fail!).times(1).with(:unknown_signature_algorithm, kind_of(OmniAuth::Facebook::SignedRequest::UnknownSignatureAlgorithmError))
      strategy.callback_phase
    end
  end
end
