require "rails_helper"

RSpec.describe "OrganizationsCreate", type: :request do
  let(:user) { create(:user, :org_admin) }
  let(:organization) { attributes_for(:organization) }

  before do
    sign_in user
  end

  it "creates a new organization with proper params" do
    expect do
      post "/organizations", params: { organization: organization.merge(profile_image: fixture_file_upload("files/800x600.png", "image/png")) }
    end.to change(Organization, :count).by(1)
  end

  it "creates a new organization membership for organization" do
    post "/organizations", params: { organization: organization }
    expect(Organization.last.organization_memberships).to contain_exactly(OrganizationMembership.last)
  end

  it "catches error if profile image file name is too long" do
    form = OrganizationForm.new(organization_attributes: organization.merge(profile_updated_at: Time.current), current_user: user)
    allow(OrganizationForm).to receive(:new).and_return(form)
    allow(form).to receive(:save).and_raise(Errno::ENAMETOOLONG)
    allow(DatadogStatsClient).to receive(:increment)

    post "/organizations", params: { organization: organization.merge(profile_image: fixture_file_upload("files/800x600.png", "image/png")) }

    tags = hash_including(tags: instance_of(Array))

    expect(DatadogStatsClient).to have_received(:increment).with("image_upload_error", tags)
  end

  it "returns error if profile image file name is too long" do
    form = OrganizationForm.new(organization_attributes: organization.merge(profile_updated_at: Time.current), current_user: user)
    allow(OrganizationForm).to receive(:new).and_return(form)
    allow(form).to receive(:save).and_raise(Errno::ENAMETOOLONG)
    image = fixture_file_upload("files/800x600.png", "image/png")
    allow(image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")

    post "/organizations", params: { organization: organization.merge(profile_image: image) }

    expect(response.body).to include("filename too long")
  end

  it "returns error if profile image is not a file" do
    allow(Organization).to receive(:find_by).and_return(organization)
    image = "A String"

    post "/organizations", params: { organization: organization.merge(profile_image: image) }

    expect(response.body).to include("invalid file type")
  end
end
