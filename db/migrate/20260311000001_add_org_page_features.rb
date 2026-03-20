class AddOrgPageFeatures < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # Organizations table: add page-related columns
      add_column :organizations, :cover_image, :string
      add_column :organizations, :social_links, :jsonb, default: {}, null: false
      add_column :organizations, :header_cta, :jsonb, default: {}, null: false
      add_column :organizations, :verified, :boolean, default: false, null: false
      add_column :organizations, :verified_at, :datetime
      add_column :organizations, :verification_url, :string
      add_column :organizations, :verification_status, :string
      add_column :organizations, :verification_error, :string

      # Pages table: link to organizations
      add_reference :pages, :organization, type: :bigint, null: true, foreign_key: { on_delete: :nullify }, index: false

      # Organization lead forms
      create_table :organization_lead_forms do |t|
        t.references :organization, null: false, foreign_key: { on_delete: :cascade }
        t.string :title, null: false
        t.text :description
        t.string :button_text, null: false, default: "Sign Up"
        t.boolean :active, null: false, default: true

        t.timestamps
      end

      # Lead submissions
      create_table :lead_submissions do |t|
        t.references :organization_lead_form, null: false, foreign_key: { on_delete: :cascade }
        t.references :user, null: true, foreign_key: { on_delete: :cascade }
        t.string :name
        t.string :email
        t.string :company
        t.string :job_title
        t.string :username

        t.timestamps
      end

      add_index :lead_submissions, %i[organization_lead_form_id user_id],
                unique: true,
                where: "user_id IS NOT NULL",
                name: "idx_lead_submissions_form_user_unique"
    end
  end
end
