class AddUserVisitContextReferenceToAhoyVisits < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :ahoy_visits, :user_visit_context, null: true, index: {algorithm: :concurrently}
  end
end
