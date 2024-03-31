class AddRenderModeToBillboards < ActiveRecord::Migration[7.0]
  def change
    # enums
    add_column :display_ads, :render_mode, :integer, default: 0
    add_column :display_ads, :template, :integer, default: 0
  end
end
