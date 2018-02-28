class AddLookingForWorkToUsers < ActiveRecord::Migration
  def change
    add_column :users, :looking_for_work, :boolean, default: false
    add_column :users, :looking_for_work_publicly, :boolean, default: false
  end
end
