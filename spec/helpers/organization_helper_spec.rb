require "rails_helper"

describe OrganizationHelper, type: :helper do
  it "display the correct options" do
    org1 = create(:organization)
    org2 = create(:organization)
    allow(org1).to receive(:unspent_credits_count).and_return(1)

    options = helper.orgs_with_credits([org1, org2])
    expect(options).to include("#{org1.name} (1)")
    expect(options).to include("#{org2.name} (0)")
  end
end
