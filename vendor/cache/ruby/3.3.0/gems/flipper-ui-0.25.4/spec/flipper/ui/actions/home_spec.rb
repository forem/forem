RSpec.describe Flipper::UI::Actions::Home do
  describe 'GET /' do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get '/'
    end

    it 'responds with redirect' do
      expect(last_response.status).to be(302)
      expect(last_response.headers['Location']).to eq('/features')
    end
  end
end
