class AddExtraReferencesToLiquidEmbeds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :liquid_embed_references, :referenced, polymorphic: true, null: true, index: { algorithm: :concurrently }
    add_column :liquid_embed_references, :options, :string
  end
end
