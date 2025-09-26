class AddUserQueryToEmails < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :emails, :user_query, null: true, validate: false, index: {algorithm: :concurrently}
  end
end
