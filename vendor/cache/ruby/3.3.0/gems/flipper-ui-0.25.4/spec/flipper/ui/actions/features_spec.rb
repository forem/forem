RSpec.describe Flipper::UI::Actions::Features do
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

  describe 'GET /features' do
    context "when there are some features" do
      before do
        flipper[:stats].enable
        flipper[:search].enable
        get '/features'
      end

      it 'responds with success' do
        expect(last_response.status).to be(200)
      end

      it 'renders template' do
        expect(last_response.body).to include('stats')
        expect(last_response.body).to include('search')
      end
    end

    context "when there are no features to list" do
      before do
        @original_fun_enabled = Flipper::UI.configuration.fun
        Flipper::UI.configuration.fun = fun_mode
      end

      after do
        Flipper::UI.configuration.fun = @original_fun_enabled
      end

      context "when fun mode is enabled" do
        let(:fun_mode) { true }
        before { get '/features' }

        it 'responds with success' do
          expect(last_response.status).to be(200)
        end

        it 'renders template' do
          expect(last_response.body).to include('And I\'ll flip your features.')
        end
      end

      context "when fun mode is disabled" do
        let(:fun_mode) { false }
        before { get '/features' }

        it 'responds with success' do
          expect(last_response.status).to be(200)
        end

        it 'renders template' do
          expect(last_response.body).to include('You have not added any features to configure yet.')
        end
      end
    end
  end

  describe 'POST /features' do
    let(:feature_name) { 'notifications_next' }

    before do
      @original_feature_creation_enabled = Flipper::UI.configuration.feature_creation_enabled
      Flipper::UI.configuration.feature_creation_enabled = feature_creation_enabled
      post '/features',
           { 'value' => feature_name, 'authenticity_token' => token },
           'rack.session' => session
    end

    after do
      Flipper::UI.configuration.feature_creation_enabled = @original_feature_creation_enabled
    end

    context 'feature_creation_enabled set to true' do
      let(:feature_creation_enabled) { true }

      it 'adds feature' do
        expect(flipper.features.map(&:key)).to include('notifications_next')
      end

      it 'redirects to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/notifications_next')
      end

      context 'feature name has whitespace at beginning and end' do
        let(:feature_name) { '  notifications_next   ' }

        it 'adds feature without whitespace' do
          expect(flipper.features.map(&:key)).to include('notifications_next')
        end
      end

      context 'feature name contains space' do
        let(:feature_name) { 'notifications next' }

        it 'adds feature with space' do
          expect(flipper.features.map(&:key)).to include('notifications next')
        end

        it 'redirects to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['Location']).to eq('/features/notifications%20next')
        end
      end

      context 'for an invalid feature name' do
        context 'empty feature name' do
          let(:feature_name) { '' }

          it 'does not add feature' do
            expect(flipper.features.map(&:key)).to eq([])
          end

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/new?error=%22%22%20is%20not%20a%20valid%20feature%20name.')
          end
        end

        context 'nil feature name' do
          let(:feature_name) { nil }

          it 'does not add feature' do
            expect(flipper.features.map(&:key)).to eq([])
          end

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/new?error=%22%22%20is%20not%20a%20valid%20feature%20name.')
          end
        end
      end
    end

    context 'feature_creation_enabled set to false' do
      let(:feature_creation_enabled) { false }

      it 'does not add feature' do
        expect(flipper.features.map(&:key)).not_to include('notifications_next')
      end

      it 'returns 403' do
        expect(last_response.status).to be(403)
      end

      it 'renders feature creation disabled template' do
        expect(last_response.body).to include('Feature creation is disabled.')
      end
    end
  end
end
