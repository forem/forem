class CreateTagSubforemRelationships < ActiveRecord::Migration[7.0]
  def change
    create_table :tag_subforem_relationships do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :subforem, null: false, foreign_key: true
      t.boolean :supported, default: true
      t.timestamps
    end
  end
end
