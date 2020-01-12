class AddCreateByUserIdToPodcasts < ActiveRecord::Migration[5.2]
  def change
    add_column :podcasts, :creator_id, :integer
    add_index :podcasts, :creator_id
    add_foreign_key :podcasts, :users, column: :creator_id, null: true
  end
end
