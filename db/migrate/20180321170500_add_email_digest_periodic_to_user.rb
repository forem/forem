class AddEmailDigestPeriodicToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_digest_periodic, :boolean, default: true, null: false
  end
end
