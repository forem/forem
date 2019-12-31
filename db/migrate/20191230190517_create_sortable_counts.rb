class CreateSortableCounts < ActiveRecord::Migration[5.2]
  def change
    create_table :sortable_counts do |t|
      t.bigint :countable_id, null: false
      t.string :countable_type, null: false
      t.string :slug, null: false
      t.string :title, null: false
      t.float :number, null: false, default: 0
      t.timestamps
    end
    add_index :sortable_counts, :countable_id
    add_index :sortable_counts, :countable_type
    add_index :sortable_counts, :number
    add_index :sortable_counts, :slug
  end
end
