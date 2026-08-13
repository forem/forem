class AddSimilarityThresholdToConcepts < ActiveRecord::Migration[7.0]
  def change
    add_column :concepts, :similarity_threshold, :float
  end
end
