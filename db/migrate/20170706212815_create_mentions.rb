class CreateMentions < ActiveRecord::Migration
  def change
    create_table :mentions do |t|
      t.integer :mentionable_id
      t.string :mentionable_type
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
