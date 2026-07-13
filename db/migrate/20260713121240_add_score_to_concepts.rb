class AddScoreToConcepts < ActiveRecord::Migration[8.0]
  def change
    add_column :concepts, :score, :float, default: 0.0, null: false
  end
end
