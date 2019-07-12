require "rails_helper"

RSpec.describe ProMemberships::Biller, type: :service do
  context "when there are expiring memberships with enough credits" do
    let(:pro_membership) { create(:pro_membership) }
    let(:user) { pro_membership.user }

    before do
      create_list(:credit, ProMembership::MONTHLY_COST, user: user)
    end

    it "renews the membership" do
      Timecop.travel(pro_membership.expires_at) do
        described_class.call
        pro_membership.reload
        expect(pro_membership.expires_at.to_i).to eq(1.month.from_now.to_i)
        expect(pro_membership.status).to eq("active")
      end
    end

    it "subtracts the correct amount of credits" do
      Timecop.travel(pro_membership.expires_at) do
        expect do
          described_class.call
        end.to change(user.credits.spent, :size).by(ProMembership::MONTHLY_COST)
      end
    end
  end

  context "when there are expiring memberships with insufficient credits" do
    let(:pro_membership) { create(:pro_membership) }

    it "expires the membership" do
      Timecop.travel(pro_membership.expires_at) do
        described_class.call
        pro_membership.reload
        expect(pro_membership.expired?).to be(true)
        expect(pro_membership.status).to eq("expired")
      end
    end
  end

  # context "when there are expiring memberships with insufficient credits and auto recharge" do
  # end
end
