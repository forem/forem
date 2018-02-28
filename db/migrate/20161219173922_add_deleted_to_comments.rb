class AddDeletedToComments < ActiveRecord::Migration
  def change
    add_column :comments, :deleted, :boolean, default: false
  end
end
