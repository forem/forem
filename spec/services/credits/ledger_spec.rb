require "rails_helper"

RSpec.describe Credits::Ledger, type: :service do
  let(:user) { create(:user) }
  let(:org) { create(:organization) }
  let(:user_listing) { create(:listing, user: user) }
  let(:org_listing) { create(:listing, organization: org) }

  def buy(purchaser, purchase, cost)
    params = {
      spent: true,
      spent_at: Time.current,
      purchase_type: purchase.class.name,
      purchase_id: purchase.id
    }
    params.merge!((
      purchaser.is_a?(User) ? { user: purchaser } : { organization: purchaser }))
    create_list(:credit, cost, params)
  end

  it "returns a list of user purchases with their costs" do
    Timecop.freeze(Time.current) do
      start = Time.current
      buy(user, user_listing, 3)

      items = described_class.call(user)[[User.name, user.id]]
      expect(items.length).to be(1)

      item = items.first
      expect(item.purchase.is_a?(Listing)).to be(true)
      expect(item.cost).to eq(3)
      expect(item.purchased_at.to_i >= start.to_i).to be(true)
    end
  end

  it "returns a list of purchases for the org the user is an admin for" do
    create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "admin")
    buy(org, org_listing, 3)
    items = described_class.call(user)[[Organization.name, org.id]]
    expect(items.length).to be(1)
  end

  it "does not return purchases for other orgs the user belongs to" do
    create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "member")
    buy(org, org_listing, 3)
    items = described_class.call(user)[[Organization.name, org.id]]
    expect(items).to be_nil
  end
end
