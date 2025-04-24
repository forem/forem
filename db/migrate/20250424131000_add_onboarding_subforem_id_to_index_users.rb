class AddOnboardingSubforemIdToIndexUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :users, :onboarding_subforem_id, algorithm: :concurrently
  end
end
