class DropBlazer < ActiveRecord::Migration[7.0]
  def change
    drop_table :blazer_audits
    drop_table :blazer_checks
    drop_table :blazer_dashboard_queries
    drop_table :blazer_dashboards
    drop_table :blazer_queries
  end
end
