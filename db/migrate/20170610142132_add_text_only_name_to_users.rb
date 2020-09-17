class AddTextOnlyNameToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :text_only_name, :string
  end
end
