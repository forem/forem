class CreateEmailSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :email_subscriptions do |t|
      t.references :email_subscribable, polymorphic: true, null: false, index: { name: :email_subscribable_type_and_id }
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index(
      :email_subscriptions,
      %i[user_id email_subscribable_id email_subscribable_type],
      unique: true,
      name: :user_id_email_subscribable_type_and_id
    )
  end
end
