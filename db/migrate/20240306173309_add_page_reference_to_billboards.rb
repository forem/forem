class AddPageReferenceToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :display_ads, :page, type: :bigint, index: { algorithm: :concurrently }
  end
end
