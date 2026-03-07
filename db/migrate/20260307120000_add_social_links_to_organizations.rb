class AddSocialLinksToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :social_links, :jsonb, default: {}, null: false
  end
end
