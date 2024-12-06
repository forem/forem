RSpec.describe Flipper::UI::Actions::AddFeature do
  describe 'GET /features/new with feature_creation_enabled set to true' do
    before do
      @original_feature_creation_enabled = Flipper::UI.configuration.feature_creation_enabled
      Flipper::UI.configuration.feature_creation_enabled = true
      get '/features/new'
    end

    after do
      Flipper::UI.configuration.feature_creation_enabled = @original_feature_creation_enabled
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      form = '<form action="/features" method="post" class="form-inline mb-2">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'GET /features/new with feature_creation_enabled set to false' do
    before do
      @original_feature_creation_enabled = Flipper::UI.configuration.feature_creation_enabled
      Flipper::UI.configuration.feature_creation_enabled = false
      get '/features/new'
    end

    after do
      Flipper::UI.configuration.feature_creation_enabled = @original_feature_creation_enabled
    end

    it 'returns 403' do
      expect(last_response.status).to be(403)
    end

    it 'renders feature creation disabled template' do
      expect(last_response.body).to include('Feature creation is disabled.')
    end
  end
end
