class DropHtmlVariantTrackingTables < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      drop_table :html_variant_trials
      drop_table :html_variant_successes
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigratione
  end
end
