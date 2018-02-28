class AddPismoToLinks < ActiveRecord::Migration
  def change
    add_column :links, :pismo_response_json, :text
    add_column :links, :pismo_body, :text
    add_column :links, :pismo_html, :text
    add_column :links, :pismo_description, :text
    add_column :links, :pismo_keywords, :text
  end
end
