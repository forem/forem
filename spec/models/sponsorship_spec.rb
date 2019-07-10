require "rails_helper"

RSpec.describe Sponsorship, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:organization).inverse_of(:sponsorships) }
  it { is_expected.to belong_to(:sponsorable).optional }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:organization) }
  it { is_expected.to validate_inclusion_of(:level).in_array(%w[gold silver bronze tag media devrel]) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w[none pending live]) }
  it { is_expected.to allow_values(nil).for(:expires_at) }
  it { is_expected.not_to allow_values(nil).for(:featured_number) }
  it { is_expected.to have_db_index(:level) }
  it { is_expected.to have_db_index(:status) }
  it { is_expected.to have_db_index(%i[sponsorable_id sponsorable_type]) }

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
end
