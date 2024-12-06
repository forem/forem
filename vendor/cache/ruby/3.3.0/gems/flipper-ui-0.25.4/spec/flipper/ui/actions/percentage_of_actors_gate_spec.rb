RSpec.describe Flipper::UI::Actions::PercentageOfActorsGate do
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

  describe 'POST /features/:feature/percentage_of_actors' do
    context 'with valid value' do
      before do
        post 'features/search/percentage_of_actors',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper[:search].percentage_of_actors_value).to be(24)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end
    end

    context 'with space in feature name' do
      before do
        post 'features/sp%20ace/percentage_of_actors',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper["sp ace"].percentage_of_actors_value).to be(24)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/sp%20ace')
      end
    end

    context 'with invalid value' do
      before do
        post 'features/search/percentage_of_actors',
             { 'value' => '555', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not change value' do
        expect(flipper[:search].percentage_of_actors_value).to be(0)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search?error=Invalid%20percentage%20of%20actors%20value:%20value%20must%20be%20a%20positive%20number%20less%20than%20or%20equal%20to%20100,%20but%20was%20555')
      end
    end
  end
end
