class CreateIdentities < ActiveRecord::Migration[4.2]
  def change
    create_table :identities do |t|
      # t.references :user, index: true
      t.integer :user_id
      t.string :provider
      t.string :uid

      t.timestamps null: false
    end
    # add_foreign_key :identities, :users
  end
end
