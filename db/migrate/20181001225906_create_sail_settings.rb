class CreateSailSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :sail_settings do |t|
      t.string :name, null: false
      t.text :description
      t.string :value, null: false
      t.integer :cast_type, null: false, limit: 1
      t.timestamps
      t.index ["name"], name: "index_settings_on_name", unique: true
    end

    [
        { name: :display_sponsors, cast_type: :boolean, value: false, description: "Home page sponsor display" },
        { name: :live_starting_soon, cast_type: :boolean, value: false, description: "/live event is starting soon." },
        { name: :live_is_live, cast_type: :boolean, value: false, description: "/live page showing live event" },
        { name: :she_coded, cast_type: :boolean, value: false, description: "Toggle #shecoded sidebar" },
        { name: :upcoming_events, cast_type: :boolean, value: true, description: "Toggle upcoming events in sidebar" }
    ].each { |setting_info| Sail::Setting.create(setting_info) }

    drop_table :flipflop_features
  end
end
