class IndexOrganizationEmailDomains < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index(
      :organization_email_domains, %i[organization_id domain],
      unique: true, algorithm: :concurrently, name: "index_org_email_domains_on_org_and_domain"
    )
    add_index :organization_email_domains, :status, algorithm: :concurrently
  end
end
