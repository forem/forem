class CreateUserQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :user_queries do |t|
      t.string :name, null: false
      t.text :description
      t.text :query, null: false
      t.bigint :created_by_id, null: false
      t.datetime :last_executed_at
      t.integer :execution_count, default: 0, null: false
      t.integer :max_execution_time_ms, default: 30000, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :user_queries, :created_by_id
    add_index :user_queries, :active
    add_index :user_queries, :name, unique: true
    add_index :user_queries, :last_executed_at
    
    add_foreign_key :user_queries, :users, column: :created_by_id, validate: false
  end
end
