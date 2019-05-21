class AddReadingTimeToReactions < ActiveRecord::Migration[5.2]
  def change
    add_column :reactions, :reading_time, :integer, default: 0
  end
end
