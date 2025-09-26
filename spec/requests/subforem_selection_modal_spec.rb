require "rails_helper"

RSpec.describe "Subforem Selection Modal", type: :request do
  let(:user) { create(:user) }
  let(:root_subforem) { create(:subforem, domain: "root.com", root: true, discoverable: true) }
  let(:subforem1) { create(:subforem, domain: "subforem1.com", discoverable: true) }
  let(:subforem2) { create(:subforem, domain: "subforem2.com", discoverable: true) }

  before do
    sign_in user
    # Set up the root subforem context
    RequestStore.store[:subforem_id] = root_subforem.id
    RequestStore.store[:root_subforem_id] = root_subforem.id
    RequestStore.store[:default_subforem_id] = root_subforem.id

    # Mock the domain lookup to return our root subforem
    allow(Subforem).to receive(:cached_id_by_domain).and_return(root_subforem.id)
    allow(Subforem).to receive(:cached_root_id).and_return(root_subforem.id)
    allow(Subforem).to receive(:cached_default_id).and_return(root_subforem.id)
  end

  after do
    RequestStore.store[:subforem_id] = nil
    RequestStore.store[:root_subforem_id] = nil
    RequestStore.store[:default_subforem_id] = nil
  end

  describe "Modal presence in layout" do
    it "includes the subforem selection modal when on root subforem" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("subforem-selection-modal")
      expect(response.body).to include("Choose a community to post to")
    end

    it "does not include the modal when not on root subforem" do
      RequestStore.store[:subforem_id] = subforem1.id
      # Also update the mocks to reflect the new subforem context
      allow(Subforem).to receive(:cached_id_by_domain).and_return(subforem1.id)

      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("subforem-selection-modal")
    end
  end
end
