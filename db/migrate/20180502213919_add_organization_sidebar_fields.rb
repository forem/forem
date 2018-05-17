class AddOrganizationSidebarFields < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :cta_button_text, :string
    add_column :organizations, :cta_button_url, :string
    add_column :organizations, :cta_body_markdown, :text
    add_column :organizations, :cta_processed_html, :text
  end
end
