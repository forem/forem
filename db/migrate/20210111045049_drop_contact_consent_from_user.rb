class DropContactConsentFromUser < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :users, :contact_consent }
  end
end
