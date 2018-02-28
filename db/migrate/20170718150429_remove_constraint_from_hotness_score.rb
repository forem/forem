class RemoveConstraintFromHotnessScore < ActiveRecord::Migration
  def change
    change_column :articles, :hotness_score, :integer, :null => true
    change_column :tags, :hotness_score, :integer, :null => true
  end
end
