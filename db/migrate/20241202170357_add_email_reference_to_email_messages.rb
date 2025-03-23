class AddEmailReferenceToEmailMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_reference :ahoy_messages, :email, type: :bigint, index: { algorithm: :concurrently }
  end
end
