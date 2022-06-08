class AddNameToUsersGDPRDeleteRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :users_gdpr_delete_requests, :name, :string
  end
end
