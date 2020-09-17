class AddLookingForWorkToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :looking_for_work, :boolean, default: false
    add_column :users, :looking_for_work_publicly, :boolean, default: false
  end
end
