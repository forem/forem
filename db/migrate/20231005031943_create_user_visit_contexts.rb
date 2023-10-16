class CreateUserVisitContexts < ActiveRecord::Migration[7.0]
  def change
    create_table :user_visit_contexts do |t|
      t.string    :geolocation
      t.text      :user_agent
      t.text      :accept_language
      t.datetime  :last_visit_at
      t.bigint    :visit_count, default: 0
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_visit_contexts, 
              [:geolocation, :user_agent, :accept_language, :user_id], 
              unique: true, 
              name: "index_user_visit_contexts_on_all_attributes"
  end
end
