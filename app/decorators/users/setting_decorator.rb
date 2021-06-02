module Users
  class SettingDecorator < ApplicationDecorator
    def config_font_name
      config_font.gsub("default", Settings::UserExperience.default_font)
    end
  end
end
