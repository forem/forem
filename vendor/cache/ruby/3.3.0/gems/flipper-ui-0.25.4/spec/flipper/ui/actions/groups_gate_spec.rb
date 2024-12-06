RSpec.describe Flipper::UI::Actions::GroupsGate do
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

  describe 'GET /features/:feature/groups' do
    before do
      Flipper.register(:admins, &:admin?)
      get 'features/search/groups'
    end

    after do
      Flipper.unregister_groups
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new group form' do
      form = '<form action="/features/search/groups" method="post" class="form-inline">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'POST /features/:feature/groups' do
    let(:group_name) { 'admins' }

    before do
      Flipper.register(:admins, &:admin?)
    end

    after do
      Flipper.unregister_groups
    end

    context 'enabling a group' do
      before do
        post 'features/search/groups',
             { 'value' => group_name, 'operation' => 'enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to members' do
        expect(flipper[:search].groups_value).to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'feature name contains space' do
        before do
          post 'features/sp%20ace/groups',
               { 'value' => group_name, 'operation' => 'enable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'adds item to members' do
          expect(flipper["sp ace"].groups_value).to include('admins')
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['Location']).to eq('/features/sp%20ace')
        end
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].groups_value).to include('admins')
        end
      end

      context 'for an unregistered group' do
        context 'unknown group name' do
          let(:group_name) { 'not_here' }

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The%20group%20named%20%22not_here%22%20has%20not%20been%20registered.')
          end
        end

        context 'empty group name' do
          let(:group_name) { '' }

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The%20group%20named%20%22%22%20has%20not%20been%20registered.')
          end
        end

        context 'nil group name' do
          let(:group_name) { nil }

          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The%20group%20named%20%22%22%20has%20not%20been%20registered.')
          end
        end
      end
    end

    context 'disabling a group' do
      let(:group_name) { 'admins' }

      before do
        flipper[:search].enable_group :admins
        post 'features/search/groups',
             { 'value' => group_name, 'operation' => 'disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from members' do
        expect(flipper[:search].groups_value).not_to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].groups_value).not_to include('admins')
        end
      end
    end
  end
end
