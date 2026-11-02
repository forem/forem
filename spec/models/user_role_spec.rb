require "rails_helper"

RSpec.describe UserRole do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:role) }

  it "indexes role_id for role-to-users lookups" do
    indexed_columns = described_class.connection.indexes(:users_roles).map(&:columns)
    expect(indexed_columns).to include(["role_id"])
  end

  it "finds users holding a resource role via with_role" do
    tag = create(:tag)
    moderator = create(:user)
    create(:user)
    moderator.add_role(:tag_moderator, tag)

    expect(User.with_role(:tag_moderator, tag).ids).to eq([moderator.id])
  end
end
