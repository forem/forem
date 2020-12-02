require "rails_helper"

RSpec.describe "OrganizationsUpdate", type: :request do
  let(:user) { create(:user, :org_admin) }
  let(:org_id) { user.organizations.first.id }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }

  before do
    sign_in user
  end

  it "updates org color with proper params" do
    put "/organizations/#{org_id}", params: {
      organization: { id: org_id, text_color_hex: "#111111" }
    }
    expect(Organization.last.text_color_hex).to eq("#111111")
  end

  it "generates new secret" do
    secret = Organization.last.secret
    post "/organizations/generate_new_secret", params: {
      organization: { id: org_id }
    }
    expect(Organization.last.secret).not_to eq(secret)
  end

  it "updates profile_updated_at" do
    Organization.last.update_column(:profile_updated_at, 2.weeks.ago)
    put "/organizations/#{org_id}", params: { organization: { id: org_id, text_color_hex: "#111111" } }
    expect(Organization.last.profile_updated_at).to be > 2.minutes.ago
  end

  it "updates nav_image" do
    put "/organizations/#{org_id}", params: { organization: { id: org_id,
                                                              nav_image: fixture_file_upload("podcast.png",
                                                                                             "image/png") } }
    expect(Organization.find(org_id).nav_image_url).to be_present
  end

  it "returns not_found if organization is missing" do
    invalid_id = org_id + 100
    expect do
      put "/organizations/#{invalid_id}", params: { organization: { id: invalid_id, text_color_hex: "#111111" } }
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "returns error if profile image file name is too long" do
    organization = user.organizations.first
    allow(Organization).to receive(:find_by).and_return(organization)
    image = fixture_file_upload("800x600.png", "image/png")
    allow(image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")

    put "/organizations/#{org_id}", params: { organization: { id: org_id, profile_image: image } }

    expect(response.body).to include("filename too long")
  end

  it "returns error if profile image is not a file" do
    organization = user.organizations.first
    allow(Organization).to receive(:find_by).and_return(organization)
    image = "A String"

    put "/organizations/#{org_id}", params: { organization: { id: org_id, profile_image: image } }

    expect(response.body).to include("invalid file type")
  end
end
