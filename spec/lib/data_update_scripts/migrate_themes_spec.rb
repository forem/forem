require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211019063703_migrate_themes.rb",
)

describe DataUpdateScripts::MigrateThemes do
  let(:user) { create(:user) }

  it "leaves default theme users on light and leaves OS sync enabled" do
    user.setting.update_columns(config_theme: 0)

    expect { described_class.new.run }
      .to not_change { user.setting.reload.config_theme }.from("light_theme")
      .and not_change { user.setting.prefer_os_color_scheme }.from(true)
  end

  it "updates minimal theme users to light and disables OS sync" do
    user.setting.update_columns(config_theme: 1)

    expect { described_class.new.run }
      .to change { user.setting.reload.config_theme }.to("light_theme")
      .and change { user.setting.prefer_os_color_scheme }.from(true).to(false)
  end

  it "updates night theme users to dark and disables OS sync" do
    user.setting.update_columns(config_theme: 2)

    expect { described_class.new.run }
      .to not_change { user.setting.reload.config_theme }.from("dark_theme")
      .and change { user.setting.prefer_os_color_scheme }.from(true).to(false)
  end

  it "updates pink theme users to light and leaves OS sync enabled" do
    user.setting.update_columns(config_theme: 3)

    expect { described_class.new.run }
      .to change { user.setting.reload.config_theme }.to("light_theme")
      .and not_change { user.setting.prefer_os_color_scheme }.from(true)
  end

  it "updates ten x hacker theme users to dark and disables OS sync" do
    user.setting.update_columns(config_theme: 4)

    expect { described_class.new.run }
      .to change { user.setting.reload.config_theme }.to("dark_theme")
      .and change { user.setting.prefer_os_color_scheme }.from(true).to(false)
  end
end
