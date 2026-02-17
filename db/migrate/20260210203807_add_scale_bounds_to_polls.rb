class AddScaleBoundsToPolls < ActiveRecord::Migration[7.0]
  def change
    add_column :polls, :scale_min, :integer
    add_column :polls, :scale_max, :integer
  end
end
