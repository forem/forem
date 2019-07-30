require "rails_helper"

RSpec.describe Credit, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:random_number) { rand(100) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:organization).optional }
  it { is_expected.to belong_to(:purchase).optional }

  xit "counts credits for user" do
    # See https://github.com/magnusvk/counter_culture/issues/259

    create_list(:credit, random_number, user: user)
    described_class.counter_culture_fix_counts
    expect(user.reload.credits_count).to eq(random_number)
  end

  it "counts credits for organization" do
    create_list(:credit, random_number, organization: organization)
    described_class.counter_culture_fix_counts
    expect(organization.reload.credits_count).to eq(random_number)
  end

  it "counts the number of unspent credits for a user" do
    create_list(:credit, random_number, user: user)
    expect(user.reload.unspent_credits_count).to eq(random_number)
  end

  it "counts the number of spent credits for a user" do
    create_list(:credit, random_number, user: user, spent: true)
    expect(user.reload.spent_credits_count).to eq(random_number)
  end

  it "counts the number of unspent credits for an organization" do
    create_list(:credit, random_number, organization: organization)
    expect(organization.reload.unspent_credits_count).to eq(random_number)
  end

  it "counts the number of spent credits for an organization" do
    create_list(:credit, random_number, organization: organization, spent: true)
    expect(organization.reload.spent_credits_count).to eq(random_number)
  end

  describe "#purchase" do
    let(:listing) { create(:classified_listing) }

    it "associates to a purchase" do
      credit = create(:credit, purchase: listing)
      expect(credit.purchase).to eq(listing)
    end

    it "is valid without a purchase" do
      credit = create(:credit, purchase: nil)
      expect(credit).to be_valid
    end
  end
end
