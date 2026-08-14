class CreateLiquidEmbedReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :liquid_embed_references do |t|
      t.references :record, polymorphic: true, null: false
      t.string :tag_name, null: false
      t.string :url

      t.timestamps
    end
    
    add_index :liquid_embed_references, [:tag_name, :url]
  end
end
