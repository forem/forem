require 'helper'
require 'omniauth/facebook/signed_request'

class SignedRequestTest < Minitest::Test
  def setup
    @value = fixture('signed_request.txt').strip
    @secret = "897z956a2z7zzzzz5783z458zz3z7556"
    @expected_payload = MultiJson.decode(fixture('payload.json'))
  end

  def test_signed_request_payload
    signed_request = OmniAuth::Facebook::SignedRequest.new(@value, @secret)
    assert_equal @expected_payload, signed_request.payload
  end

  def test_signed_request_parse
    payload = OmniAuth::Facebook::SignedRequest.parse(@value, @secret)
    assert_equal @expected_payload, payload
  end

  private

  def fixture(name)
    File.read(File.expand_path("fixtures/#{name}", File.dirname(__FILE__)))
  end
end
