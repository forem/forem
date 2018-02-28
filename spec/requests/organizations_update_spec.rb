require "rails_helper"

RSpec.describe "OrganizationsUpdate", type: :request do
  let(:organization) { create(:organization)}
  let(:user) { create(:user, organization_id: organization.id) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  before do
    user.org_admin = true
    sign_in user
  end

  it "updates ordinary article with proper params" do
    put "/organizations/#{organization.id}", params: {
      organization: { text_color_hex: "#111111" },
    }
    expect(Organization.last.text_color_hex).to eq("#111111")
  end

  it "generates new secret" do
    secret = Organization.last.secret
    post "/organizations/generate_new_secret"
    expect(Organization.last.secret).not_to eq(secret)
  end
end
