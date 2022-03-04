class AddPermitAdjacentSponsorsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :permit_adjacent_sponsors, :boolean, default: true
  end
end
