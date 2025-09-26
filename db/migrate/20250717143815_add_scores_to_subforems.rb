class AddScoresToSubforems < ActiveRecord::Migration[7.0]
  def change
    add_column :subforems, :score, :integer, default: 0, null: false
    add_column :subforems, :hotness_score, :integer, default: 0, null: false
  end
end
