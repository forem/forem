class AddOnboardingPackageRequestedAgainToUsers < ActiveRecord::Migration
  def change
    add_column :users, :onboarding_package_requested_again, :boolean, default: false
  end
end
