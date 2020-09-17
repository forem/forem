class AddEditedAtToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :edited_at, :datetime
  end
end
