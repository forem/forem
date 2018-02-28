class AddTextOnlyNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :text_only_name, :string
  end
end
