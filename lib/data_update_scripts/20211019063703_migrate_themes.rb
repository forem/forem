module DataUpdateScripts
  class MigrateThemes
    FILE_NAME = "20211019063703_migrate_themes".freeze

    def run
      # NOTE: I couldn't come up with a better way to make this idempotent.
      return if DataUpdateScript.where(file_name: FILE_NAME).any?

      # No OS sync for Dark (2) users
      Users::Setting.where(config_theme: 2).update_all(prefer_os_color_scheme: false)

      # Ten X Hacker (4) -> Dark (2), no OS sync
      Users::Setting.where(config_theme: 4).update_all(config_theme: 2, prefer_os_color_scheme: false)

      # Minimal (1) -> Light (0), no OS sync
      Users::Setting.where(config_theme: 1).update_all(config_theme: 0, prefer_os_color_scheme: false)

      # Pink (3) -> Light (0), OS sync (defaults to true), the
      Users::Setting.where(config_theme: 3).update_all(config_theme: 0)
    end
  end
end
