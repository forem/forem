class AddSlugFieldToEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :events, :slug, :string if !column_exists?(:events, :slug)
    add_index :events, :slug, unique: true, algorithm: :concurrently

    reversible do |dir|
      dir.up do
        Event.reset_column_information
        Event.find_each do |event|
          event.update_columns(slug: event.title.parameterize) if event.title.present?
        end
      end
    end
  end
end
