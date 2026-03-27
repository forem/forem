class AddStatusAndScoreToLiquidEmbedReferences < ActiveRecord::Migration[7.0]
  def change
    add_column :liquid_embed_references, :published, :boolean, default: true, null: false
    add_column :liquid_embed_references, :published_at, :datetime
    add_column :liquid_embed_references, :score, :integer, default: 0, null: false
  end
end
