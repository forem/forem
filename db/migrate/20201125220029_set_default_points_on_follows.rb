class SetDefaultPointsOnFollows < ActiveRecord::Migration[6.0]
  def change
    change_column_default :posts, :explicit_points, from: nil, to: 1.0
    change_column_default :posts, :implicit_points, from: nil, to: 0.0
  end
end
