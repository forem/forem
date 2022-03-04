class AddMembershipStartDateToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :membership_started_at, :datetime
  end
end
