class AddIndexesToIdentities < ActiveRecord::Migration[5.1]
  def change
    add_index :identities, %i[provider uid], unique: true
    add_index :identities, %i[provider user_id], unique: true
  end
end
