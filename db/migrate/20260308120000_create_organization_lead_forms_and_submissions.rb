class CreateOrganizationLeadFormsAndSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :organization_lead_forms do |t|
      t.references :organization, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :description
      t.string :button_text, null: false, default: "Sign Up"
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    create_table :lead_submissions do |t|
      t.references :organization_lead_form, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name
      t.string :email
      t.string :company
      t.string :job_title
      t.string :location

      t.timestamps
    end

    add_index :lead_submissions, %i[organization_lead_form_id user_id], unique: true, name: "idx_lead_submissions_form_user_unique"
  end
end
