class AddCheckedTermsAndConditionsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :checked_terms_and_conditions, :bool, default: false
  end
end
