class CreateWebpageTracking < ActiveRecord::Migration[7.0]
  def change
    create_table :linked_domains do |t|
      t.string :host, null: false
      t.integer :net_score, default: 0, null: false
      t.timestamps
    end
    add_index :linked_domains, :host, unique: true

    create_table :webpage_references do |t|
      t.references :record, polymorphic: true, null: false, index: true
      t.references :linked_domain, null: false, index: true
      t.string :url, null: false
      t.timestamps
    end
    add_index :webpage_references, [:linked_domain_id, :record_type, :record_id], name: "idx_webpage_refs_on_domain_and_record"
  end
end
