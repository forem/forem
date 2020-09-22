require 'jwt'

RSpec.describe 'using OAuth2 with Google' do
  # This describes authenticating to a Google API via a service account.
  # See their docs: https://developers.google.com/identity/protocols/OAuth2ServiceAccount

  describe 'via 2-legged JWT assertion' do
    let(:client) do
      OAuth2::Client.new(
        '',
        '',
        :site => 'https://accounts.google.com',
        :authorize_url => '/o/oauth2/auth',
        :token_url => '/o/oauth2/token',
        :auth_scheme => :request_body
      )
    end

    # These are taken directly from Google's documentation example:

    let(:required_claims) do
      {
        'iss' => '761326798069-r5mljlln1rd4lrbhg75efgigp36m78j5@developer.gserviceaccount.com',
        # The email address of the service account.

        'scope' => 'https://www.googleapis.com/auth/devstorage.readonly https://www.googleapis.com/auth/prediction',
        # A space-delimited list of the permissions that the application requests.

        'aud' => 'https://www.googleapis.com/oauth2/v4/token',
        # A descriptor of the intended target of the assertion. When making an access token request this value
        # is always https://www.googleapis.com/oauth2/v4/token.

        'exp' => Time.now.to_i + 3600,
        # The expiration time of the assertion, specified as seconds since 00:00:00 UTC, January 1, 1970. This value
        # has a maximum of 1 hour after the issued time.

        'iat' => Time.now.to_i,
        # The time the assertion was issued, specified as seconds since 00:00:00 UTC, January 1, 1970.
      }
    end

    let(:optional_claims) do
      {
        'sub' => 'some.user@example.com'
        # The email address of the user for which the application is requesting delegated access.
      }
    end

    let(:algorithm) { 'RS256' }
    # Per Google: "Service accounts rely on the RSA SHA-256 algorithm"

    let(:key) do
      begin
        OpenSSL::PKCS12.new(File.read('spec/fixtures/google_service_account_key.p12'), 'notasecret').key
        # This simulates the .p12 file that Google gives you to download and keep somewhere.  This is meant to
        # illustrate extracting the key and using it to generate the JWT.
      rescue OpenSSL::PKCS12::PKCS12Error
        # JRuby CI builds are blowing up trying to extract a sample key for some reason.  This simulates the end result
        # of actually figuring out the problem.
        OpenSSL::PKey::RSA.new(1024)
      end
    end
    # Per Google:

    # "Take note of the service account's email address and store the service account's P12 private key file in a
    # location accessible to your application. Your application needs them to make authorized API calls."

    let(:encoding_options) { {:key => key, :algorithm => algorithm} }

    before do
      client.connection.build do |builder|
        builder.adapter :test do |stub|
          stub.post('https://accounts.google.com/o/oauth2/token') do |token_request|
            @request_body = token_request.body

            [
              200,

              {
                'Content-Type' => 'application/json',
              },

              {
                'access_token' => '1/8xbJqaOZXSUZbHLl5EOtu1pxz3fmmetKx9W8CV4t79M',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
              }.to_json,
            ]
          end
        end
      end
    end

    context 'when passing the required claims' do
      let(:claims) { required_claims }

      it 'sends a JWT with the 5 keys' do
        client.assertion.get_token(claims, encoding_options)

        expect(@request_body).not_to be_nil, 'No access token request was made!'
        expect(@request_body[:grant_type]).to eq('urn:ietf:params:oauth:grant-type:jwt-bearer')
        expect(@request_body[:assertion]).to be_a(String)

        payload, header = JWT.decode(@request_body[:assertion], key, true, :algorithm => algorithm)
        expect(header['alg']).to eq('RS256')
        expect(payload.keys).to match_array(%w[iss scope aud exp iat])

        # Note that these specifically do _not_ include the 'sub' claim, which is indicated as being 'required'
        # by the OAuth2 JWT RFC: https://tools.ietf.org/html/rfc7523#section-3
        # This may indicate that this is a nonstandard use case by Google.

        payload.each do |key, value|
          expect(value).to eq(claims[key])
        end
      end
    end

    context 'when including the optional `sub` claim' do
      let(:claims) { required_claims.merge(optional_claims) }

      it 'sends a JWT with the 6 keys' do
        client.assertion.get_token(claims, encoding_options)

        expect(@request_body).not_to be_nil, 'No access token request was made!'
        expect(@request_body[:grant_type]).to eq('urn:ietf:params:oauth:grant-type:jwt-bearer')
        expect(@request_body[:assertion]).to be_a(String)

        payload, header = JWT.decode(@request_body[:assertion], key, true, :algorithm => algorithm)
        expect(header['alg']).to eq('RS256')
        expect(payload.keys).to match_array(%w[iss scope aud exp iat sub])

        payload.each do |key, value|
          expect(value).to eq(claims[key])
        end
      end
    end
  end
end
