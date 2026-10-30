class CreateOrganizationEmailDomains < ActiveRecord::Migration[7.0]
  def change
    create_table :organization_email_domains do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :requested_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :reviewed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :domain, null: false, limit: 253
      t.string :status, null: false, default: "pending"
      t.boolean :enabled, null: false, default: false
      t.datetime :reviewed_at
      t.timestamps
    end

    create_table :organization_membership_challenges do |t|
      t.references :organization_email_domain, null: false, foreign_key: true, index: { name: "index_org_challenges_on_domain" }
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :otp_digest, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :consumed_at
      t.timestamps
    end
  end
end
