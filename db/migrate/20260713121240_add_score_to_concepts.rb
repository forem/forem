class AddScoreToConcepts < ActiveRecord::Migration[7.2]
  def change
    add_column :concepts, :score, :float, default: 0.0, null: false
  end
end
