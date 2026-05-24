class AddLastPresenceAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_presence_at, :datetime
  end
end
