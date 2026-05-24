class AddPageTemplateIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :page_templates, :name, unique: true, algorithm: :concurrently
    add_index :page_templates, :forked_from_id, algorithm: :concurrently
    add_index :pages, :page_template_id, algorithm: :concurrently
  end
end

