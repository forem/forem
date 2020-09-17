class CreateUserSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :user_subscriptions do |t|
      t.references :user_subscription_sourceable, polymorphic: true, null: false, index: { name: :index_on_user_subscription_sourcebable_type_and_id }
      t.references :subscriber, references: :users, foreign_key: { to_table: :users }, null: false
      t.references :author, references: :users, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    add_index(
      :user_subscriptions,
      %i[subscriber_id user_subscription_sourceable_id user_subscription_sourceable_type],
      unique: true,
      name: :index_on_subscriber_id_user_subscription_sourceable_type_and_id
    )
  end
end
