class CreateSubforems < ActiveRecord::Migration[7.0]
  def change
    create_table :subforems do |t|
      t.string :domain, null: false, unique: true
      t.timestamps
    end
    add_index :subforems, :domain, unique: true
  end
end
