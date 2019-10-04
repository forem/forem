class AddGroupToSailSettings < ActiveRecord::Migration[5.2]
  def change
    add_column(:sail_settings, :group, :string)
  end
end
