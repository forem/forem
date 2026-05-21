require "rails_helper"

RSpec.describe "ActiveRecordUnionIntegration", type: :model do
  let!(:user_a) { create(:user, username: "uniontest_a", email: "uniontest_a@example.com") }
  let!(:user_b) { create(:user, username: "uniontest_b", email: "uniontest_b@example.com") }
  let!(:user_c) { create(:user, username: "uniontest_c", email: "uniontest_c@example.com") }

  describe "union method" do
    it "combines two active record relations into a single set without duplicates" do
      relation_1 = User.where(id: [user_a.id, user_b.id])
      relation_2 = User.where(id: [user_b.id, user_c.id])

      union_relation = relation_1.union(relation_2)

      expect(union_relation).to be_an(ActiveRecord::Relation)
      expect(union_relation.count).to eq(3)
      expect(union_relation.pluck(:id)).to contain_exactly(user_a.id, user_b.id, user_c.id)
    end

    it "allows chaining further active record methods like where or select" do
      relation_1 = User.where(id: [user_a.id, user_b.id])
      relation_2 = User.where(id: [user_c.id])

      union_relation = relation_1.union(relation_2).where(username: "uniontest_b")

      expect(union_relation.count).to eq(1)
      expect(union_relation.first).to eq(user_b)
    end
  end

  describe "union_all method" do
    it "combines two active record relations keeping duplicates" do
      relation_1 = User.where(id: [user_a.id, user_b.id])
      relation_2 = User.where(id: [user_b.id, user_c.id])

      union_all_relation = relation_1.union_all(relation_2)

      expect(union_all_relation).to be_an(ActiveRecord::Relation)
      # Some databases optimized count or select, we'll pluck to verify all elements are present
      ids = union_all_relation.pluck(:id)
      expect(ids.count).to eq(4)
      expect(ids).to include(user_a.id, user_b.id, user_c.id)
      expect(ids.count(user_b.id)).to eq(2)
    end
  end
end
