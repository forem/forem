class AddProfileFieldGroupToProfileField < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_reference :profile_fields, :profile_field_group, index: { algorithm: :concurrently }
    add_foreign_key :profile_fields, :profile_field_groups, validate: false
  end
end
