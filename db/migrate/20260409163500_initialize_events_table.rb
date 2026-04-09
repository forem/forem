class InitializeEventsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :primary_stream_url
      t.boolean :published, default: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.jsonb :data, default: {}
      t.integer :type_of, default: 0
      
      t.string :event_name_slug, null: false
      t.string :event_variation_slug, null: false

      t.references :user, null: true, foreign_key: true
      t.references :organization, foreign_key: true

      t.string :cached_tag_list
      t.text :tags_array, default: [], array: true

      t.timestamps
    end

    add_index :events, [:event_name_slug, :event_variation_slug], unique: true
    add_index :events, :tags_array, using: :gin
  end
end
