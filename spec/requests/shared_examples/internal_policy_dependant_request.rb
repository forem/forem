RSpec.shared_examples "an InternalPolicy dependant request" do |resource|
  let(:user) { create(:user) }

  before do
    user.add_role(:single_resource_admin, resource)
    sign_in user
    allow(InternalPolicy).to receive(:new).and_call_original
  end

  it "responds with 200 OK" do
    request
    expect(response).to have_http_status(:success)
    expect(InternalPolicy).to have_received(:new).with(user, resource)
  end
end
