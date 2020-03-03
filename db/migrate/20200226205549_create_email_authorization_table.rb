class CreateEmailAuthorizationTable < ActiveRecord::Migration[5.2]
  def change
    create_table :email_authorizations do |t|
      t.references :user
      t.jsonb :json_data, null: false, default: {}
      t.string :type_of, null: false
      t.timestamp :verified_at
      t.timestamps null: false
    end

    add_index :email_authorizations, %i[user_id type_of], unique: true

    add_foreign_key :email_authorizations, :users, on_delete: :cascade, validate: false
  end
end
