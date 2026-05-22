require "rails_helper"

RSpec.describe "ActiveRecordUnion", type: :lib do
  with_model :UnionTestModel do
    table do |t|
      t.string :name
      t.integer :age
    end
  end

  it "unions two relations correctly" do
    record1 = UnionTestModel.create!(name: "Alice", age: 30)
    record2 = UnionTestModel.create!(name: "Bob", age: 40)
    record3 = UnionTestModel.create!(name: "Charlie", age: 50)

    relation1 = UnionTestModel.where(name: "Alice")
    relation2 = UnionTestModel.where(name: "Bob")

    union_relation = relation1.union(relation2)

    expect(union_relation.to_a).to contain_exactly(record1, record2)
    expect(union_relation.to_a).not_to include(record3)
  end

  it "unions with union_all correctly" do
    record1 = UnionTestModel.create!(name: "Alice", age: 30)
    record2 = UnionTestModel.create!(name: "Bob", age: 40)

    relation1 = UnionTestModel.where(name: "Alice")
    relation2 = UnionTestModel.where(name: "Bob")

    union_all_relation = relation1.union_all(relation2)

    expect(union_all_relation.to_a).to contain_exactly(record1, record2)
  end
end
