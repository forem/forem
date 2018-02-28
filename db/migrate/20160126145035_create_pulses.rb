class CreatePulses < ActiveRecord::Migration
  def change
    create_table :pulses do |t|
      t.integer :pulse_subscription_id
      t.integer :link_id
      t.text    :body
      t.string  :category
      t.timestamps null: false
    end
  end
end
