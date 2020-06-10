class CreateEmailSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :email_subscriptions do |t|
      t.references :email_subscribable, polymorphic: true, null: false, index: { name: :email_subscribable_type_and_id }
      t.references :subscriber, references: :users, foreign_key: { to_table: :users }, null: false
      t.references :author, references: :users, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    add_index(
      :email_subscriptions,
      %i[subscriber_id email_subscribable_id email_subscribable_type],
      unique: true,
      name: :index_on_subscriber_id_email_subscribable_type_and_id
    )
  end
end
