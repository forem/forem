require 'helper'

describe OmniAuth::Strategies::Developer do
  let(:app) do
    Rack::Builder.new do |b|
      b.use Rack::Session::Cookie, :secret => 'abc123'
      b.use OmniAuth::Strategies::Developer
      b.run lambda { |_env| [200, {}, ['Not Found']] }
    end.to_app
  end

  context 'request phase' do
    before(:each) { get '/auth/developer' }

    it 'displays a form' do
      expect(last_response.status).to eq(200)
      expect(last_response.body).to be_include('<form')
    end

    it 'has the callback as the action for the form' do
      expect(last_response.body).to be_include("action='/auth/developer/callback'")
    end

    it 'has a text field for each of the fields' do
      expect(last_response.body.scan('<input').size).to eq(2)
    end
  end

  context 'callback phase' do
    let(:auth_hash) { last_request.env['omniauth.auth'] }

    context 'with default options' do
      before do
        post '/auth/developer/callback', :name => 'Example User', :email => 'user@example.com'
      end

      it 'sets the name in the auth hash' do
        expect(auth_hash.info.name).to eq('Example User')
      end

      it 'sets the email in the auth hash' do
        expect(auth_hash.info.email).to eq('user@example.com')
      end

      it 'sets the uid to the email' do
        expect(auth_hash.uid).to eq('user@example.com')
      end
    end

    context 'with custom options' do
      let(:app) do
        Rack::Builder.new do |b|
          b.use Rack::Session::Cookie, :secret => 'abc123'
          b.use OmniAuth::Strategies::Developer, :fields => %i[first_name last_name], :uid_field => :last_name
          b.run lambda { |_env| [200, {}, ['Not Found']] }
        end.to_app
      end

      before do
        @options = {:uid_field => :last_name, :fields => %i[first_name last_name]}
        post '/auth/developer/callback', :first_name => 'Example', :last_name => 'User'
      end

      it 'sets info fields properly' do
        expect(auth_hash.info.name).to eq('Example User')
      end

      it 'sets the uid properly' do
        expect(auth_hash.uid).to eq('User')
      end
    end
  end
end
