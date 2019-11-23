class RemoveConstraintFromHotnessScore < ActiveRecord::Migration[4.2]
  def change
    change_column :articles, :hotness_score, :integer, :null => true
    change_column :tags, :hotness_score, :integer, :null => true
  end
end
