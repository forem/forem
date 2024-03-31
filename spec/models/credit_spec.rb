require "rails_helper"

RSpec.describe Credit do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:organization).optional }
  it { is_expected.to belong_to(:purchase).optional }

  context "when caching counters" do
    let(:user_credits) { create_list(:credit, 2, user: user) }
    let(:org_credits) { create_list(:credit, 1, organization: organization) }

    describe "#credits_count" do
      it "counts credits for user" do
        # See https://github.com/magnusvk/counter_culture/issues/259
        described_class.counter_culture_fix_counts
        expect(user.reload.credits_count).to eq(user.credits.size)
      end

      it "counts credits for organization" do
        described_class.counter_culture_fix_counts
        expect(organization.reload.credits_count).to eq(organization.credits.size)
      end
    end

    describe "#unspent_credits_count" do
      it "counts the number of unspent credits for a user" do
        expect(user.reload.unspent_credits_count).to eq(user.credits.unspent.size)
      end

      it "counts the number of unspent credits for an organization" do
        expect(organization.reload.unspent_credits_count).to eq(organization.credits.unspent.size)
      end
    end

    describe "#spent_credits_count" do
      it "counts the number of spent credits for a user" do
        create_list(:credit, 1, user: user, spent: true)
        expect(user.reload.spent_credits_count).to eq(user.credits.spent.size)
      end

      it "counts the number of spent credits for an organization" do
        create_list(:credit, 1, organization: organization, spent: true)
        expect(organization.reload.spent_credits_count).to eq(organization.credits.spent.size)
      end
    end
  end

  describe "#purchase" do
    let(:credit) { build(:credit) }

    it "is valid with a purchase" do
      credit.purchase = build(:listing)
      expect(credit).to be_valid
    end

    it "is valid without a purchase" do
      credit.purchase = nil
      expect(credit).to be_valid
    end
  end

  describe "#add_to" do
    it "adds the credits to the user" do
      expect do
        described_class.add_to(user, 1)
      end.to change { user.reload.unspent_credits_count }.by(1)
    end

    it "adds the credits to the organization" do
      expect do
        described_class.add_to(organization, 1)
      end.to change { organization.reload.unspent_credits_count }.by(1)
    end
  end

  describe "#remove_from" do
    let(:user_credits) { create_list(:credit, 2, user: user) }
    let(:org_credits) { create_list(:credit, 1, organization: organization) }

    before { [user_credits, org_credits] }

    it "adds the credits to the user" do
      expect do
        described_class.remove_from(user, 1)
      end.to change { user.reload.unspent_credits_count }.by(-1)
    end

    it "adds the credits to the organization" do
      expect do
        described_class.remove_from(organization, 1)
      end.to change { organization.reload.unspent_credits_count }.by(-1)
    end
  end
end
