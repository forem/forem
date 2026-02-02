class CreateLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :labels do |t|
      t.string :slug, null: false, unique: true
      t.string :name, null: false
      t.string :description
      t.timestamps
      t.index :slug, unique: true
    end
  end
end
