class RemoveUnusedColumnsFromUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :users, :base_cover_letter, :text
      remove_column :users, :membership_started_at, :datetime
      remove_column :users, :onboarding_checklist, :string, array: true, default: []
      remove_column :users, :onboarding_package_form_submmitted_at, :datetime
      remove_column :users, :onboarding_package_fulfilled, :boolean, default: false
      remove_column :users, :onboarding_package_requested_again, :boolean, default: false
      remove_column :users, :onboarding_variant_version, :string, default: "0"
      remove_column :users, :org_admin, :boolean, default: false
      remove_column :users, :personal_data_updated_at, :datetime
      remove_column :users, :resume_html, :text
      remove_column :users, :shipping_validated, :boolean, default: false
      remove_column :users, :shipping_validated_at, :datetime
      remove_column :users, :shirt_gender, :string
      remove_column :users, :shirt_size, :string
      remove_column :users, :signup_refer_code, :string
      remove_column :users, :signup_referring_site, :string
      remove_column :users, :specialty, :string
      remove_column :users, :tabs_or_spaces, :string
      remove_column :users, :text_only_name, :string
      remove_column :users, :top_languages, :string
    end
  end
end
