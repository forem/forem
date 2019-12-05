class AddPolymorphismToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :commentable_id, :integer
    add_column :comments, :commentable_type, :string
    add_column :comments, :score, :integer, default: 0
  end
end
