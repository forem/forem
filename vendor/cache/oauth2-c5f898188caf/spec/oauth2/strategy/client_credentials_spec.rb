RSpec.describe OAuth2::Strategy::ClientCredentials do
  subject { client.client_credentials }

  let(:kvform_token) { 'expires_in=600&access_token=salmon&refresh_token=trout' }
  let(:json_token) { '{"expires_in":600,"access_token":"salmon","refresh_token":"trout"}' }

  let(:client) do
    OAuth2::Client.new('abc', 'def', :site => 'http://api.example.com') do |builder|
      builder.adapter :test do |stub|
        stub.post('/oauth/token', 'grant_type' => 'client_credentials') do |env|
          client_id, client_secret = Base64.decode64(env[:request_headers]['Authorization'].split(' ', 2)[1]).split(':', 2)
          client_id == 'abc' && client_secret == 'def' || raise(Faraday::Adapter::Test::Stubs::NotFound)
          @last_headers = env[:request_headers]
          case @mode
          when 'formencoded'
            [200, {'Content-Type' => 'application/x-www-form-urlencoded'}, kvform_token]
          when 'json'
            [200, {'Content-Type' => 'application/json'}, json_token]
          end
        end
        stub.post('/oauth/token', 'client_id' => 'abc', 'client_secret' => 'def', 'grant_type' => 'client_credentials') do |env|
          case @mode
          when 'formencoded'
            [200, {'Content-Type' => 'application/x-www-form-urlencoded'}, kvform_token]
          when 'json'
            [200, {'Content-Type' => 'application/json'}, json_token]
          end
        end
      end
    end
  end

  describe '#authorize_url' do
    it 'raises NotImplementedError' do
      expect { subject.authorize_url }.to raise_error(NotImplementedError)
    end
  end

  %w[json formencoded].each do |mode|
    [:basic_auth, :request_body].each do |auth_scheme|
      describe "#get_token (#{mode}) (#{auth_scheme})" do
        before do
          @mode = mode
          client.options[:auth_scheme] = auth_scheme
          @access = subject.get_token
        end

        it 'returns AccessToken with same Client' do
          expect(@access.client).to eq(client)
        end

        it 'returns AccessToken with #token' do
          expect(@access.token).to eq('salmon')
        end

        it 'returns AccessToken without #refresh_token' do
          expect(@access.refresh_token).to be_nil
        end

        it 'returns AccessToken with #expires_in' do
          expect(@access.expires_in).to eq(600)
        end

        it 'returns AccessToken with #expires_at' do
          expect(@access.expires_at).not_to be_nil
        end
      end
    end
  end

  describe '#get_token (with extra header parameters)' do
    before do
      @mode = 'json'
      @access = subject.get_token(:headers => {'X-Extra-Header' => 'wow'})
    end

    it 'sends the header correctly.' do
      expect(@last_headers['X-Extra-Header']).to eq('wow')
    end
  end
end
