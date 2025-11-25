class CreatePageTemplates < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      execute "SET statement_timeout = 0;"

      create_table :page_templates do |t|
        t.string :name, null: false
        t.text :description
        t.text :body_html
        t.text :body_markdown
        t.jsonb :data_schema, null: false, default: {}
        t.string :template_type, default: "contained"
        t.bigint :forked_from_id
        t.timestamps
      end

      add_index :page_templates, :name, unique: true, algorithm: :concurrently
      add_index :page_templates, :forked_from_id, algorithm: :concurrently

      # Add page_template_id and template_data to pages
      add_column :pages, :page_template_id, :bigint
      add_column :pages, :template_data, :jsonb, default: {}

      add_index :pages, :page_template_id, algorithm: :concurrently
    end
  end
end
