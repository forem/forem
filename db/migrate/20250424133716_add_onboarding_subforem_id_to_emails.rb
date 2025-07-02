class AddOnboardingSubforemIdToEmails < ActiveRecord::Migration[7.0]
  def change
    add_column :emails, :onboarding_subforem_id, :bigint
  end
end
