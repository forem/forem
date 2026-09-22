class AddCloudflareCustomHostnameFieldsToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :cloudflare_custom_hostname_id, :string
    add_column :organizations, :custom_domain_error, :string
  end
end
