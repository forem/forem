class AddAnchorToAdd < ActiveRecord::Migration
  def change
    add_column :advertisements, :anchor_text, :string
  end
end
