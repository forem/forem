class AddFeatureFlagToPage < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :feature_flag, :string
  end
end
