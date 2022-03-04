class AddTaglineToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :tag_line, :string
  end
end
