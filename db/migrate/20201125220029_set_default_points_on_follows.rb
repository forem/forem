class SetDefaultPointsOnFollows < ActiveRecord::Migration[6.0]
  def change
    change_column_default :follows, :explicit_points, from: nil, to: 1.0
    change_column_default :follows, :implicit_points, from: nil, to: 0.0
  end
end
