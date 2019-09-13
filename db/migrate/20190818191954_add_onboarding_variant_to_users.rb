class AddOnboardingVariantToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :onboarding_variant_version, :string, default: "0"
  end
end
