class AddContactConsentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :contact_consent, :boolean, default:false
  end
end
