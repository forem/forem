module SettingsHelper
  def user_experience_labels
    [
      I18n.t("helpers.settings_helper.novice"),
      I18n.t("helpers.settings_helper.beginner"),
      I18n.t("helpers.settings_helper.mid_level"),
      I18n.t("helpers.settings_helper.advanced"),
      I18n.t("helpers.settings_helper.expert"),
    ]
  end

  def user_experience_levels
    %w[1 3 5 8 10]
  end
end
