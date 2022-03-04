class AddOnboardingChecklistToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :onboarding_checklist, :string, array: true, default: []
  end
end
