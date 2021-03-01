class ValidateForeignKeyOnProfileField < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :profile_fields, :profile_field_groups
  end
end
