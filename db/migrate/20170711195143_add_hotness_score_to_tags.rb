class AddHotnessScoreToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :hotness_score, :integer, null: false, default: 0
  end
end
