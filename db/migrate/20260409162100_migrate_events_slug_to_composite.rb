class MigrateEventsSlugToComposite < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_column :events, :event_name_slug, :string
    add_column :events, :event_variation_slug, :string

    Event.reset_column_information
    Event.find_each do |e|
      # Graceful fallback for existing seeds before strictly validating
      e.update_columns(
        event_name_slug: e.title.present? ? e.title.parameterize : "event-#{e.id}",
        event_variation_slug: "v1"
      )
    end

    add_index :events, [:event_name_slug, :event_variation_slug], unique: true, algorithm: :concurrently

    safety_assured do
      remove_index :events, :slug if index_exists?(:events, :slug)
      remove_column :events, :slug, :string if column_exists?(:events, :slug)
    end
  end

  def down
    add_column :events, :slug, :string unless column_exists?(:events, :slug)
    
    Event.reset_column_information
    Event.find_each do |e|
      e.update_columns(slug: "#{e.event_name_slug}-#{e.event_variation_slug}")
    end

    add_index :events, :slug, unique: true, algorithm: :concurrently

    safety_assured do
      remove_index :events, [:event_name_slug, :event_variation_slug] if index_exists?(:events, [:event_name_slug, :event_variation_slug])
      remove_column :events, :event_variation_slug, :string
      remove_column :events, :event_name_slug, :string
    end
  end
end
