class RemoveActiveFromProfileFields2 < ActiveRecord::Migration[6.0]
  def up
    return unless column_exists?(:profile_fields, :active)

    safety_assured { remove_column :profile_fields, :active }
  end

  def down
    return if column_exists?(:profile_fields, :active)

    add_column :profile_fields, :active, :boolean
  end
end
