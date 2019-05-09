require "rails_helper"

RSpec.describe Credit, type: :model do
  it "counts credits for user" do
    user = create(:user)
    Credit.create(user_id: user.id)
    Credit.create(user_id: user.id)
    expect(user.reload.credits_count).to eq(2)
  end
  it "counts credits for organization" do
    organization = create(:organization)
    Credit.create(organization_id: organization.id)
    expect(organization.reload.credits_count).to eq(1)
  end
end
