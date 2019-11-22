class AddPulsedToLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :links, :pulsed, :boolean, default: false
    add_column :links, :ids_for_pulse_subscriptions_hit, :text, default: [].to_yaml
    add_column :links, :num_pulse_subscriptions_hit, :integer
  end
end
