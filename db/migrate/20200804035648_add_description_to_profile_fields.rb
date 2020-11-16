class AddDescriptionToProfileFields < ActiveRecord::Migration[6.0]
  def change
    add_column :profile_fields, :description, :string
  end
end
