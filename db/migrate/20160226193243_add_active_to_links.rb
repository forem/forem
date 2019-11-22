class AddActiveToLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :links, :active, :boolean, default: true
  end
end
