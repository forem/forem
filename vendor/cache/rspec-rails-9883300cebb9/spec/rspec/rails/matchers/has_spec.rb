class CollectionOwner < ActiveRecord::Base
  connection.execute <<-SQL
    CREATE TABLE collection_owners (
      id integer PRIMARY KEY AUTOINCREMENT
    )
  SQL
  has_many :associated_items do
    def has_some_quality?; true end
  end
end

class AssociatedItem < ActiveRecord::Base
  connection.execute <<-SQL
    CREATE TABLE associated_items (
      id integer PRIMARY KEY AUTOINCREMENT,
      collection_owner_id integer
    )
  SQL
  belongs_to :collection_owner
end

RSpec.describe "should have_xxx" do
  it "works with ActiveRecord::Associations::CollectionProxy" do
    owner = CollectionOwner.new
    expect(owner.associated_items).to have_some_quality
  end
end
