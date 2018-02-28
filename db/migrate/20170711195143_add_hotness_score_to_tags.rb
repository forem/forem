class AddHotnessScoreToTags < ActiveRecord::Migration
  def change
    add_column :tags, :hotness_score, :integer, null: false, default: 0
  end
end
