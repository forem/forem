class AddJsonbDataColumnToAuditLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :audit_logs, :data, :jsonb, null: false, default: {}
    add_index :audit_logs, :data, using: :gin
  end
end
