class AddAdditionalColumnsToAuditLog < ActiveRecord::Migration[5.2]
  def change
    add_column(:audit_logs, :slug, :string)
    add_column(:audit_logs, :category, :string)
  end
end
