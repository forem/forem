class UpdateLeadSubmissionsForAnonymousSupport < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      change_table :lead_submissions do |t|
        t.remove :location, type: :string
        t.string :username
      end

      change_column_null :lead_submissions, :user_id, true

      remove_index :lead_submissions, name: "idx_lead_submissions_form_user_unique", algorithm: :concurrently
      add_index :lead_submissions, %i[organization_lead_form_id user_id],
                unique: true,
                where: "user_id IS NOT NULL",
                name: "idx_lead_submissions_form_user_unique",
                algorithm: :concurrently
    end
  end
end
