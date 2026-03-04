class AddPageFieldsToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :page_markdown, :text
    add_column :organizations, :processed_page_html, :text
    add_column :organizations, :cover_image, :string
  end
end
