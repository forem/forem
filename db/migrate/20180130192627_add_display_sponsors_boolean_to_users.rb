class AddDisplaySponsorsBooleanToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :display_sponsors, :boolean, default: true
  end
end
