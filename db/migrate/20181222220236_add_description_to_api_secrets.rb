class AddDescriptionToApiSecrets < ActiveRecord::Migration[5.1]
  def change
    add_column :api_secrets, :description, :string
  end
end
