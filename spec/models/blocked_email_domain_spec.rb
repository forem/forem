require "rails_helper"

RSpec.describe BlockedEmailDomain, type: :model do
  describe "validations" do
    it "validates presence of domain" do
      blocked_domain = described_class.new
      expect(blocked_domain).not_to be_valid
      expect(blocked_domain.errors[:domain]).to include("can't be blank")
    end

    it "validates uniqueness of domain" do
      described_class.create!(domain: "example.com")
      duplicate = described_class.new(domain: "example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:domain]).to include("has already been taken")
    end

    it "validates domain format" do
      invalid_domains = ["invalid", "example..com", "example.com.", "example@com"]
      invalid_domains.each do |invalid_domain|
        blocked_domain = described_class.new(domain: invalid_domain)
        expect(blocked_domain).not_to be_valid, "#{invalid_domain} should be invalid"
        expect(blocked_domain.errors[:domain]).to include("must be a valid domain")
      end
    end

    it "accepts valid domains" do
      valid_domains = ["example.com", "sub.example.com", "test-domain.co.uk", "example.org"]
      valid_domains.each do |valid_domain|
        blocked_domain = described_class.new(domain: valid_domain)
        expect(blocked_domain).to be_valid, "#{valid_domain} should be valid"
      end
    end
  end

  describe "normalization" do
    it "normalizes domain to lowercase" do
      blocked_domain = described_class.create!(domain: "EXAMPLE.COM")
      expect(blocked_domain.domain).to eq("example.com")
    end

    it "strips whitespace from domain" do
      blocked_domain = described_class.create!(domain: "  example.com  ")
      expect(blocked_domain.domain).to eq("example.com")
    end
  end

  describe ".blocked?" do
    before do
      described_class.create!(domain: "example.com")
      described_class.create!(domain: "blocked.org")
    end

    it "returns true for exact matches" do
      expect(described_class.blocked?("example.com")).to be true
      expect(described_class.blocked?("blocked.org")).to be true
    end

    it "returns true for subdomain matches" do
      expect(described_class.blocked?("sub.example.com")).to be true
      expect(described_class.blocked?("deep.sub.example.com")).to be true
      expect(described_class.blocked?("test.blocked.org")).to be true
    end

    it "returns false for non-blocked domains" do
      expect(described_class.blocked?("allowed.com")).to be false
      expect(described_class.blocked?("different.org")).to be false
    end

    it "returns false for blank or nil domains" do
      expect(described_class.blocked?("")).to be false
      expect(described_class.blocked?(nil)).to be false
    end

    it "is case insensitive" do
      expect(described_class.blocked?("EXAMPLE.COM")).to be true
      expect(described_class.blocked?("SUB.EXAMPLE.COM")).to be true
    end
  end

  describe ".domains" do
    it "returns array of blocked domains" do
      described_class.create!(domain: "example.com")
      described_class.create!(domain: "blocked.org")

      domains = described_class.domains
      expect(domains).to contain_exactly("example.com", "blocked.org")
    end
  end
end
