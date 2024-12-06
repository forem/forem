RSpec.describe Flipper::UI::Actions::File do
  describe 'GET /images/logo.png' do
    before do
      get '/images/logo.png'
    end

    it 'responds with 200' do
      expect(last_response.status).to be(200)
    end
  end

  describe 'GET /css/application.css' do
    before do
      get '/css/application.css'
    end

    it 'responds with 200' do
      expect(last_response.status).to be(200)
    end
  end
end
