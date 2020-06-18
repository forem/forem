class AddBodyJsonToPage < ActiveRecord::Migration[6.0]
  def change
    add_column :pages, :body_json, :jsonb
  end
end
