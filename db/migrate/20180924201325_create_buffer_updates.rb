class CreateBufferUpdates < ActiveRecord::Migration[5.1]
  def change
    create_table :buffer_updates do |t|
      t.integer :article_id, null: false
      t.integer :tag_id
      t.text    :body_text
      t.string  :buffer_profile_id_code
      t.string  :buffer_id_code
      t.string  :social_service_name
      t.text    :buffer_response, default: {}.to_yaml
      t.timestamps
    end
  end
end
