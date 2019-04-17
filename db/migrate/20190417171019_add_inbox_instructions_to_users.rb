class AddInboxInstructionsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :inbox_guidelines, :string
  end
end
