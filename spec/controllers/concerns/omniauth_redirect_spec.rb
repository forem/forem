require "rails_helper"

# rubocop:disable Style/OpenStructUse
# rubocop:disable Performance/OpenStruct
RSpec.describe "Omniauth redirect", type: :request do
  let!(:user) { create(:user) }
  let!(:controller) { ApplicationController.new }
  let!(:mock_warden) { Warden::Proxy.new({}, Warden::Manager.new(nil)) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:stored_location_for).and_return(nil)
    allow(controller).to receive(:root_path).and_return("/new")
  end

  it "avoids i=i param in after_sign_in_path_for" do
    mock_request = OpenStruct.new(env: { "warden" => mock_warden })
    allow(controller).to receive(:request).and_return(mock_request)

    path = controller.after_sign_in_path_for(user)
    expect(path).not_to include("i=i")
    expect(path).to end_with("/new?signin=true")
  end

  it "respects the origin param passed through the OAuth flow" do
    mock_env = { "omniauth.origin" => "/settings", "warden" => mock_warden }
    mock_request = OpenStruct.new(env: mock_env)
    allow(controller).to receive(:request).and_return(mock_request)

    path = controller.after_sign_in_path_for(user)
    expect(path).not_to include("i=i")
    expect(path).to end_with("/settings?signin=true")
  end
end
# rubocop:enable Style/OpenStructUse
# rubocop:enable Performance/OpenStruct
