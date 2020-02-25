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
    let(:user) { create(:user, :org_member) }
    let(:org) { user.organizations.first }

    it "forbids an org to have multiple 'expiring' (bronze-silver-gold) sponsorships" do
      create(:sponsorship, level: :gold, organization: org, expires_at: 2.days.from_now)
      bronze_sponsorship = build(:sponsorship, level: :bronze, organization: org)
      expect(bronze_sponsorship).not_to be_valid
      expect(bronze_sponsorship.errors[:level]).to be_present
    end

    it "allows to create a new sponsorship for the same org if the previous one is expired" do
      create(:sponsorship, expires_at: 1.day.ago, user: user, organization: org, level: :bronze)
      bronze_sponsorship = build(:sponsorship, level: :bronze, user: user, organization: org)
      expect(bronze_sponsorship).to be_valid
    end

    it "allows to create a new sponsorship for the same level for another org" do
      create(:sponsorship, level: :gold, organization: org, expires_at: 2.days.from_now)
      other_org = create(:organization)
      gold_sponsorship = build(:sponsorship, level: :gold, organization: other_org)
      expect(gold_sponsorship).to be_valid
    end

    context "when tag sponsorships" do
      let(:python) { create(:tag, name: "python") }
      let(:ruby) { create(:tag, name: "ruby") }

      it "allows an org to have multiple tag sponsorships on different tags" do
        create(:sponsorship, level: :tag, organization: org, expires_at: 2.days.from_now, sponsorable: python)
        tag_sponsorship = build(:sponsorship, level: :tag, organization: org, sponsorable: ruby)
        expect(tag_sponsorship).to be_valid
      end

      it "allows to create a new tag sponsorship if the previous one is expired" do
        create(:sponsorship, user: user, organization: org, expires_at: 1.day.ago, level: :tag, sponsorable: ruby)
        ruby_sponsorship = build(:sponsorship, user: user, organization: org, level: :tag, sponsorable: ruby)
        expect(ruby_sponsorship).to be_valid
      end

      it "forbids an org to have multiple active tag sponsorships on the same tag" do
        tag = create(:tag, name: "python")
        create(:sponsorship, level: :tag, organization: org, sponsorable: tag, expires_at: 2.days.from_now)
        tag_sponsorship = build(:sponsorship, level: :tag, organization: org, sponsorable: tag)
        expect(tag_sponsorship).not_to be_valid
        expect(tag_sponsorship.errors[:level]).to be_present
      end

      it "forbids different orgs to have active sponsorships on the same tag" do
        other_org = create(:organization)
        create(:sponsorship, level: :tag, organization: org, sponsorable: python, expires_at: 2.days.from_now)
        tag_sponsorship = build(:sponsorship, level: :tag, organization: other_org, sponsorable: python)
        expect(tag_sponsorship).not_to be_valid
        expect(tag_sponsorship.errors[:level]).to be_present
      end
    end
  end
end
