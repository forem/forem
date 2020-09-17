class AddUniqueIndexToResponseTemplatesContent < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :response_templates,
      %i[content user_id type_of content_type],
      unique: true,
      algorithm: :concurrently,
      # needs a custom name as the generated one is too long
      name: :idx_response_templates_on_content_user_id_type_of_content_type
    )
  end
end
