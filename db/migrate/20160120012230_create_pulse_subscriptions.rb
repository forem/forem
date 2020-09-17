class CreatePulseSubscriptions < ActiveRecord::Migration[4.2]
  def change
    create_table :pulse_subscriptions do |t|
      t.string :team_name
      t.string :team_code
      t.string :channel
      t.string :pulses, default: [].to_yaml
      t.string :access_token
      t.string :config_url
      t.string :sending_url
      t.string :scope, default: [].to_yaml
      t.timestamps null: false
    end
  end
end
