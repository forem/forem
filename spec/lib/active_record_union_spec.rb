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
    union_records = union_relation.to_a

    expect(union_records).to contain_exactly(record1, record2)
    expect(union_records).not_to include(record3)
  end

  it "unions with union_all correctly" do
    record1 = UnionTestModel.create!(name: "Alice", age: 30)
    record2 = UnionTestModel.create!(name: "Bob", age: 40)

    relation1 = UnionTestModel.where(id: [record1.id, record2.id])
    relation2 = UnionTestModel.where(id: record1.id)

    union_all_ids = relation1.union_all(relation2).pluck(:id)

    expect(union_all_ids.count(record1.id)).to eq(2)
    expect(union_all_ids.count(record2.id)).to eq(1)
  end
end
