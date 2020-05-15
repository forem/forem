require "oauth2"
# Usage
# auth = TestAuth.new
# auth.get_access_token
#  - a link will then appear
# access_token = auth.get_auth_code(given_auth_code)
# done!!

class TestAuth
  attr_reader :client, :token
  attr_accessor :access_token

  def initialize
    id = "lsrFTS0bZknS3-xvMZ-uOB9Shw-MYfaXcPCDRb_5N9Y"
    secret = "W9ifCnvbWPXOkzHMWHlE0MCLFZC42cr1gPcK36RzlCg"
    @url = "urn:ietf:wg:oauth:2.0:oob"
    @client = OAuth2::Client.new(id, secret, site: "http://localhost:3000")
  end

  def get_access_token
    client.auth_code.authorize_url(redirect_uri: @url)
  end

  def get_auth_code(auth_code)
    @token = client.auth_code.get_token(auth_code, redirect_uri: @url)
  end
end