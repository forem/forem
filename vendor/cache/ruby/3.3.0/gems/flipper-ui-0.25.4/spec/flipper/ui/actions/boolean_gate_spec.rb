RSpec.describe Flipper::UI::Actions::BooleanGate do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end
  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  describe 'POST /features/:feature/boolean' do
    context 'with enable' do
      before do
        flipper.disable :search
        post 'features/search/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper.enabled?(:search)).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end
    end

    context "with space in feature name" do
      before do
        flipper.disable :search
        post 'features/sp%20ace/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'updates feature' do
        expect(flipper.enabled?("sp ace")).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/sp%20ace')
      end
    end

    context 'with disable' do
      before do
        flipper.enable :search
        post 'features/search/boolean',
             { 'action' => 'Disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'disables the feature' do
        expect(flipper.enabled?(:search)).to be(false)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end
    end
  end
end
