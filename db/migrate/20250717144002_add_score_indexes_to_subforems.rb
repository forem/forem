class AddScoreIndexesToSubforems < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :subforems, :score, algorithm: :concurrently
    add_index :subforems, :hotness_score, algorithm: :concurrently
  end
end
