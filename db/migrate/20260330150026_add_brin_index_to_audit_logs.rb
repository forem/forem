class AddBrinIndexToAuditLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :audit_logs, 
              :created_at, 
              using: :brin, 
              algorithm: :concurrently,
              name: "index_audit_logs_on_created_at_brin"
  end
end
