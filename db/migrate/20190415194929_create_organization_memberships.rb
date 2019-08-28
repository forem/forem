class CreateOrganizationMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_memberships do |t|
      t.bigint :user_id, null: false
      t.bigint :organization_id, null: false
      t.string :user_title
      t.string :type_of_user, null: false
      t.timestamps null: false
    end

    add_index :organization_memberships, %i[user_id organization_id], unique: true
  end
end
