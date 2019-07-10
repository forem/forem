require "rails_helper"

RSpec.describe Sponsorship, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:organization).inverse_of(:sponsorships) }
  it { is_expected.to belong_to(:sponsorable).optional }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:organization) }
  it { is_expected.to validate_inclusion_of(:level).in_array(Sponsorship::LEVELS) }
  it { is_expected.to validate_inclusion_of(:status).in_array(Sponsorship::STATUSES) }
  it { is_expected.to allow_values(nil).for(:expires_at) }
  it { is_expected.not_to allow_values(nil).for(:featured_number) }
  it { is_expected.to have_db_index(:level) }
  it { is_expected.to have_db_index(:status) }
  it { is_expected.to have_db_index(%i[sponsorable_id sponsorable_type]) }

  describe "constants" do
    it "has the correct values for constants" do
      expect(Sponsorship::LEVELS).to eq(%w[gold silver bronze tag media devrel])
      expect(Sponsorship::LEVELS_WITH_EXPIRATION).to eq(%w[gold silver bronze])
      expect(Sponsorship::STATUSES).to eq(%w[none pending live])
      expected_credits = { gold: 6000, silver: 500, bronze: 100, tag: 300, devrel: 500 }.with_indifferent_access
      expect(Sponsorship::CREDITS).to eq(expected_credits)
    end
  end

  describe "#url" do
    let(:sponsorship) { build(:sponsorship) }

    it "accepts a blank url" do
      sponsorship.url = ""
      expect(sponsorship).to be_valid
    end

    it "accepts a HTTP url" do
      sponsorship.url = "http://example.com"
      expect(sponsorship).to be_valid
    end

    it "accepts a HTTPS url" do
      sponsorship.url = "https://example.com"
      expect(sponsorship).to be_valid
    end

    it "does not accept an invalid url" do
      sponsorship.url = "example.com"
      expect(sponsorship).not_to be_valid
    end
  end

  describe "validations" do
    let(:org) { create(:organization) }

    it "forbids an org to have multiple 'expiring' sponsorships" do
      create(:sponsorship, level: :gold, organization: org)
      bronze_sponsorship = build(:sponsorship, level: :gold, organization: org)
      expect(bronze_sponsorship).not_to be_valid
    end

    context "when tag sponsorships" do
      it "allows an org to have multiple tag sponsorships on different tags" do
        create(:sponsorship, level: :tag, organization: org, sponsorable: create(:tag, name: "python"))
        tag_sponsorship = build(:sponsorship, level: :tag, organization: org, sponsorable: create(:tag, name: "ruby"))
        expect(tag_sponsorship).to be_valid
      end

      it "forbids an org to have multiple tag sponsorships on the same tag" do
        tag = create(:tag, name: "python")
        create(:sponsorship, level: :tag, organization: org, sponsorable: tag)
        tag_sponsorship = build(:sponsorship, level: :tag, organization: org, sponsorable: tag)
        expect(tag_sponsorship).not_to be_valid
      end

      it "forbids different orgs to have a sponsorship on the same tag" do
        tag = create(:tag, name: "python")
        other_org = create(:organization)
        create(:sponsorship, level: :tag, organization: org, sponsorable: tag)
        tag_sponsorship = build(:sponsorship, level: :tag, organization: other_org, sponsorable: tag)
        expect(tag_sponsorship).not_to be_valid
      end
    end
  end
end
