class AddExplicitAndImplicitFollowPoints < ActiveRecord::Migration[6.0]
  def change
    add_column :follows, :explicit_points, :float
    add_column :follows, :implicit_points, :float
  end
end
