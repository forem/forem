class CreateAuditLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :roles, array: true

      t.timestamps
    end
  end
end
