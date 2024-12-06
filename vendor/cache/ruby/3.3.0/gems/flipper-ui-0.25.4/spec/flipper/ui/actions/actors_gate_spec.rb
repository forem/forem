RSpec.describe Flipper::UI::Actions::ActorsGate do
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

  describe 'GET /features/:feature/actors' do
    before do
      get 'features/search/actors'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new actor form' do
      form = '<form action="/features/search/actors" method="post" class="form-inline">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'GET /features/:feature/actors with slash in feature name' do
    before do
      get 'features/a/b/actors'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new actor form' do
      form = '<form action="/features/a/b/actors" method="post" class="form-inline">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'POST /features/:feature/actors' do
    context 'enabling an actor' do
      let(:value) { 'User;6' }
      let(:multi_value) { 'User;5, User;7, User;9, User;12' }

      before do
        post 'features/search/actors',
             { 'value' => value, 'operation' => 'enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to members' do
        expect(flipper[:search].actors_value).to include(value)
      end

      it 'adds item to multiple members' do
        post 'features/search/actors',
             { 'value' => multi_value, 'operation' => 'enable', 'authenticity_token' => token },
             'rack.session' => session

        expect(flipper[:search].actors_value).to include('User;5')
        expect(flipper[:search].actors_value).to include('User;7')
        expect(flipper[:search].actors_value).to include('User;9')
        expect(flipper[:search].actors_value).to include('User;12')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context "when feature name contains space" do
        before do
          post 'features/sp%20ace/actors',
               { 'value' => value, 'operation' => 'enable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'adds item to members' do
          expect(flipper["sp ace"].actors_value).to include('User;6')
        end

        it "redirects back to feature" do
          expect(last_response.status).to be(302)
          expect(last_response.headers['Location']).to eq('/features/sp%20ace')
        end
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }
        let(:multi_value) { '  User;5  ,  User;7   ,  User;9 ,  User;12 ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].actors_value).to include('User;6')
        end

        it 'adds item to multi members without whitespace' do
          post 'features/search/actors',
             { 'value' => multi_value, 'operation' => 'enable', 'authenticity_token' => token },
             'rack.session' => session

          expect(flipper[:search].actors_value).to include('User;5')
          expect(flipper[:search].actors_value).to include('User;7')
          expect(flipper[:search].actors_value).to include('User;9')
          expect(flipper[:search].actors_value).to include('User;12')
        end
      end

      context 'for an invalid actor value' do
        context 'empty value' do
          let(:value) { '' }

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/actors?error=%22%22%20is%20not%20a%20valid%20actor%20value.')
          end
        end

        context 'nil value' do
          let(:value) { nil }

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/actors?error=%22%22%20is%20not%20a%20valid%20actor%20value.')
          end
        end
      end
    end

    context 'disabling an actor' do
      let(:value) { 'User;6' }
      let(:multi_value) { 'User;5, User;7, User;9, User;12' }

      before do
        flipper[:search].enable_actor Flipper::Actor.new(value)
        post 'features/search/actors',
             { 'value' => value, 'operation' => 'disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from members' do
        expect(flipper[:search].actors_value).not_to include(value)
      end

      it 'removes item from multi members' do
        multi_value.split(',').map(&:strip).each do |value|
          flipper[:search].enable_actor Flipper::Actor.new(value)
        end

        post 'features/search/actors',
             { 'value' => multi_value, 'operation' => 'disable', 'authenticity_token' => token },
             'rack.session' => session

        expect(flipper[:search].actors_value).not_to eq(Set.new(multi_value.split(',').map(&:strip)))
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }
        let(:multi_value) { '  User;5  ,  User;7   ,  User;9 ,  User;12 ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].actors_value).not_to include('User;6')
        end

        it 'removes item without whitespace' do
          multi_value.split(',').map(&:strip).each do |value|
            flipper[:search].enable_actor Flipper::Actor.new(value)
          end
          post 'features/search/actors',
              { 'value' => multi_value, 'operation' => 'disable', 'authenticity_token' => token },
              'rack.session' => session
          expect(flipper[:search].actors_value).not_to eq(Set.new(multi_value.split(',').map(&:strip)))
        end
      end
    end
  end
end
