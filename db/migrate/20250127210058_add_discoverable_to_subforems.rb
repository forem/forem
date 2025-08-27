class AddDiscoverableToSubforems < ActiveRecord::Migration[7.0]
  def change
    add_column :subforems, :discoverable, :boolean, default: false, null: false
  end
end
