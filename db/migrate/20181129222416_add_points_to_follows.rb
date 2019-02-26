class AddPointsToFollows < ActiveRecord::Migration[5.1]
  def change
    add_column :follows, :points, :float, default: 1.0
  end
end
