class AddKeyAndTokenToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :token, :string
    add_column :identities, :secret, :string

  end
end
