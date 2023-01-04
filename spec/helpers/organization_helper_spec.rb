require "rails_helper"

describe OrganizationHelper do
  it "displays the correct options" do
    org1 = create(:organization, name: "ACME")
    org2 = create(:organization, name: "Pied Piper")
    allow(org1).to receive(:unspent_credits_count).and_return(1)

    options = helper.orgs_with_credits([org1, org2])
    expect(options).to include("ACME (1)")
    expect(options).to include("Pied Piper (0)")
  end
end
