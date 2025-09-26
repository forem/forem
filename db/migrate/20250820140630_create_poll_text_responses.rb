class CreatePollTextResponses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    create_table :poll_text_responses do |t|
      t.references :poll, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :text_content

      t.timestamps
    end

    add_index :poll_text_responses, [:poll_id, :user_id], unique: true, algorithm: :concurrently
  end
end
