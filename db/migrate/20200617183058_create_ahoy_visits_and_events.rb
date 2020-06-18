class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[6.0]
  # This migration includes a subset of the available fields provided by ahoy.
  # For the full list of options, please see https://github.com/ankane/ahoy.

  def change
    create_table :ahoy_visits do |t|
      t.string :visit_token
      t.string :visitor_token

      t.references :user
      t.timestamp :started_at
    end

    add_index :ahoy_visits, [:visit_token], unique: true

    create_table :ahoy_events do |t|
      t.references :visit
      t.references :user

      t.string :name
      t.jsonb :properties
      t.timestamp :time
    end

    add_index :ahoy_events, [:name, :time]
    add_index :ahoy_events, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
