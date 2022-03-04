class ChangePulsesColumnName < ActiveRecord::Migration[4.2]
  def change
    rename_column :pulse_subscriptions, :pulses, :subscribed_categories
  end
end
