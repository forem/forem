class AddBgColorHexToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :bg_color_hex, :string
  end
end
