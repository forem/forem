class AddDisallowSubforemReassignmentToUsersSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :users_settings, :disallow_subforem_reassignment, :boolean, default: false, null: false
  end
end
