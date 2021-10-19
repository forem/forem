module Settings
  def self.tab_list
    [
      I18n.t("settings_menu.profile"),
      I18n.t("settings_menu.customization"),
      I18n.t("settings_menu.notifications"),
      I18n.t("settings_menu.account"),
      I18n.t("settings_menu.billing"),
      I18n.t("settings_menu.organization"),
      I18n.t("settings_menu.extensions"),
    ]
  end
end
