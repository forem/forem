class AddDisplayColumsToProfileFields < ActiveRecord::Migration[6.0]
  def change
    add_column :profile_fields, :display_area, :integer, null: false, default: true
    add_column :profile_fields, :show_in_onboarding, :boolean, null: false, default: false
  end
end
