class AddKeyAndTokenToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_column :identities, :token, :string
    add_column :identities, :secret, :string

  end
end
