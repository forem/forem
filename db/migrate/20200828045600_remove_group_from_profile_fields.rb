class RemoveGroupFromProfileFields < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :profile_fields, :group }
  end
end
