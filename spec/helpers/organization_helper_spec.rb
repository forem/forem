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

  describe "#custom_domain_dns_record_name" do
    it "returns the subdomain part relative to the registrable domain" do
      expect(helper.custom_domain_dns_record_name("blog.example.com")).to eq("blog")
      expect(helper.custom_domain_dns_record_name("dev.blog.example.co.uk")).to eq("dev.blog")
    end

    it "returns @ for an apex domain" do
      expect(helper.custom_domain_dns_record_name("example.com")).to eq("@")
      expect(helper.custom_domain_apex?("example.com")).to be(true)
      expect(helper.custom_domain_apex?("blog.example.com")).to be(false)
    end
  end
end
