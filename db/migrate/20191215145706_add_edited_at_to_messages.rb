class AddEditedAtToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :edited_at, :datetime
  end
end
