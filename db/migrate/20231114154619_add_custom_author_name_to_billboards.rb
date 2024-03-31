class AddCustomAuthorNameToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :custom_display_label, :string
  end
end
