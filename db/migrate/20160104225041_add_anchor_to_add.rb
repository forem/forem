class AddAnchorToAdd < ActiveRecord::Migration[4.2]
  def change
    add_column :advertisements, :anchor_text, :string
  end
end
