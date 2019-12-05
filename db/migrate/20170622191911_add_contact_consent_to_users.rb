class AddContactConsentToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :contact_consent, :boolean, default:false
  end
end
