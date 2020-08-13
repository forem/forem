class AddGroupToProfileFields < ActiveRecord::Migration[6.0]
  def change
    add_column :profile_fields, :group, :string
  end
end
