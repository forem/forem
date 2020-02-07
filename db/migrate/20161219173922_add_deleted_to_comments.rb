class AddDeletedToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :deleted, :boolean, default: false
  end
end
