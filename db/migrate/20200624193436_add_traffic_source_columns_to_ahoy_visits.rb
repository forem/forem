class AddTrafficSourceColumnsToAhoyVisits < ActiveRecord::Migration[6.0]
  def change
    # strong_migrations cannot guarantee safety ofwhat happens inside a change_table
    # block, so we need to explicitly disable the BulkChangeTable rule here.
    # rubocop:disable Rails/BulkChangeTable
    add_column :ahoy_visits, :referrer, :text
    add_column :ahoy_visits, :referring_domain, :string
    add_column :ahoy_visits, :landing_page, :text
    # rubocop:enable Rails/BulkChangeTable
  end
end
