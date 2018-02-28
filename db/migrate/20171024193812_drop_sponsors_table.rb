class DropSponsorsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :sponsors
  end
end
