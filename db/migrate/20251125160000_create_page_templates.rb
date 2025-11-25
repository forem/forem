class CreatePageTemplates < ActiveRecord::Migration[7.0]
  def change
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

    add_column :pages, :page_template_id, :bigint
    add_column :pages, :template_data, :jsonb, default: {}
  end
end
