class AddResponseTemplateIndexUserIdTypeOf < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :response_templates, %i[user_id type_of], algorithm: :concurrently
  end
end
