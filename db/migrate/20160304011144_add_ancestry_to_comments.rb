class AddAncestryToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :ancestry, :string
    add_index :comments, :ancestry
  end
end
