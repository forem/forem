module DataUpdateScripts
  class MigrateThemes
    def run
      # Night (2) or Ten X Hacker (4) -> Dark (6), no OS sync
      Users::Setting.where(config_theme: [2, 4]).update_all(config_theme: 6, prefer_os_color_scheme: false)

      # Minimal (1) -> Light (0), no OS sync
      Users::Setting.where(config_theme: 1).update_all(config_theme: 5, prefer_os_color_scheme: false)

      # Default (0) or Pink (3) -> Light (0), OS sync (defaults to true)
      Users::Setting.where(config_theme: [0, 3]).update_all(config_theme: 5)
    end
  end
end
