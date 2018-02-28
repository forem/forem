class ChangePulsesColumnName < ActiveRecord::Migration
  def change
    rename_column :pulse_subscriptions, :pulses, :subscribed_categories
  end
end
