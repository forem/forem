class CreateEmailSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :email_subscriptions do |t|
      t.references :email_subscribable, polymorphic: true, null: false, index: { name: :email_subscribable_type_and_id }
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
