class AddLastOnboardingPageToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_onboarding_page, :string
  end
end
