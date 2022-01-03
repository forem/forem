module DataUpdateScripts
  class MigrateThemesAgain
    def run
      # No OS sync for Dark (2) users
      Users::Setting
        .where(config_theme: 2)
        .update_all(prefer_os_color_scheme: false)

      # Ten X Hacker (4) -> Dark (2), no OS sync
      Users::Setting
        .where(config_theme: 4)
        .update_all(config_theme: 2, prefer_os_color_scheme: false)

      # Minimal (1) -> Light (0), no OS sync
      Users::Setting
        .where(config_theme: 1)
        .update_all(config_theme: 0, prefer_os_color_scheme: false)

      # Pink (3) -> Light (0), OS sync (defaults to true), the
      Users::Setting
        .where(config_theme: 3)
        .update_all(config_theme: 0)
    end
  end
end
