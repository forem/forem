class CreateSegmentedUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :segmented_users do |t|
      t.references :audience_segment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
