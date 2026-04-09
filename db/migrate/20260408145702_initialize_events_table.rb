class InitializeEventsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :primary_stream_text
      t.boolean :published, default: false
      t.datetime :start_time
      t.datetime :end_time
      t.integer :type_of, default: 0
      t.jsonb :data, default: {}
      t.references :user, foreign_key: true, optional: true
      t.references :organization, foreign_key: true, optional: true

      t.timestamps
    end
  end
end
