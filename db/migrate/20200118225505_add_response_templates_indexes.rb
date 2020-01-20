class AddResponseTemplatesIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :response_templates, :user_id, algorithm: :concurrently
    add_index :response_templates, :type_of, algorithm: :concurrently
  end
end
