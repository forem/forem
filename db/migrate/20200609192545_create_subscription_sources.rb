class CreateSubscriptionSources < ActiveRecord::Migration[6.0]
  def change
    create_table :subscription_sources do |t|
      t.references :subscription_sourceable, polymorphic: true, null: false, index: { name: :index_on_subscription_sourceable_type_and_id }
      t.references :subscriber, references: :users, foreign_key: { to_table: :users }, null: false
      t.references :author, references: :users, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    add_index(
      :subscription_sources,
      %i[subscriber_id subscription_sourceable_id subscription_sourceable_type],
      unique: true,
      name: :index_on_subscriber_id_subscription_sourceable_type_and_id
    )
  end
end
