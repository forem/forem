require "rails_helper"

RSpec.describe Credit, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:random_number) { rand(100) }

  it "counts credits for user" do
    create_list(:credit, random_number, user: user)
    Credit.counter_culture_fix_counts
    expect(user.reload.credits_count).to eq(random_number)
  end

  it "counts credits for organization" do
    create_list(:credit, random_number, organization: organization)
    Credit.counter_culture_fix_counts
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
end
