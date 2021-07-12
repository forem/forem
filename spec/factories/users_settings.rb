FactoryBot.define do
  factory :users_setting, class: "Users::Setting" do
    config_font { "sans_serif" }
    config_navbar { "default" }
    config_theme { "night_theme" }
    display_announcements { true }
    display_sponsors { true }
    editor_version { "v1" }
    experience_level { 1 }
    feed_mark_canonical { false }
    feed_referential_link { true }
    inbox_type { "private" }
    permit_adjacent_sponsors { true }
  end
end
