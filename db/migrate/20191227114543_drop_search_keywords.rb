class DropSearchKeywords < ActiveRecord::Migration[5.2]
  def change
    drop_table :search_keywords do |t|
      t.string :keyword
      t.string :google_result_path
      t.integer :google_position
      t.integer :google_volume
      t.integer :google_difficulty
      t.datetime :google_checked_at
      t.timestamps
    end
  end
end
