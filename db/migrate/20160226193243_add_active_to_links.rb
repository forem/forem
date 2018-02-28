class AddActiveToLinks < ActiveRecord::Migration
  def change
    add_column :links, :active, :boolean, default: true
  end
end
