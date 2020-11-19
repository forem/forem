class AddExplicitAndImplicitFollowPoints < ActiveRecord::Migration[6.0]
  def change
    add_column :follows, :explicit_points, :float, default: 1.0
    add_column :follows, :implicit_points, :float, default: 0.0
  end
end
