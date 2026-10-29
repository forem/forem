class CreateEventSignups < ActiveRecord::Migration[7.1]
  def change
    create_table :event_signups do |t|
      t.belongs_to :user, null: false, foreign_key: true, index: false
      t.belongs_to :event, null: false, foreign_key: true, index: false
      t.boolean :notified_1_day_before, default: false, null: false
      t.boolean :notified_1_hour_before, default: false, null: false

      t.timestamps
    end
  end
end
