class AddHeaderCtaToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :header_cta, :jsonb, default: {}, null: false
  end
end
