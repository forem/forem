class AddExplicitAndImplicitFollowPoints < ActiveRecord::Migration[6.0]
  def change
    add_column :follows, :explicit_points, :float, default: 1.0 # 1 is equivalent to the current default set in "score"
    add_column :follows, :implicit_points, :float, default: 0.0
  end
end
