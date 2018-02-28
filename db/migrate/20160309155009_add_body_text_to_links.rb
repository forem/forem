class AddBodyTextToLinks < ActiveRecord::Migration
  def change
    add_column :links, :body_text, :text
    add_column :links, :base_url, :string
  end
end
