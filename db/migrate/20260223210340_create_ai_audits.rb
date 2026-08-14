class CreateAiAudits < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_audits do |t|
      t.string :ai_model
      t.string :wrapper_object_class
      t.string :wrapper_object_version
      t.jsonb :request_body
      t.jsonb :response_body
      t.integer :retry_count
      t.references :affected_user, foreign_key: { to_table: :users }
      t.references :affected_content, polymorphic: true

      t.timestamps
    end
  end
end
