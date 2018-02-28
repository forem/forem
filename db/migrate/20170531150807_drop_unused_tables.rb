class DropUnusedTables < ActiveRecord::Migration
  def change
    drop_table :pulse_subscriptions
    drop_table :pulses
    drop_table :questions
    drop_table :ad_clicks
    drop_table :job_applications
    drop_table :job_listings
    drop_table :kis
    drop_table :advertisements
    drop_table :answers
  end
end
