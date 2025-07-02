class AddOnboardingSubforemIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :onboarding_subforem_id, :integer
  end
end
