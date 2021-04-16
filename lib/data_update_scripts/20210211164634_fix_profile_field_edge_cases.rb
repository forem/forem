module DataUpdateScripts
  class FixProfileFieldEdgeCases
    def run
      ProfileField.where(attribute_name: %w[git_lab_url linked_in_url stack_overflow_url dribbble_url])
        .update_all(display_area: "settings_only")
      ProfileField.where(attribute_name: "skills_languages").update_all(display_area: "left_sidebar")
    end
  end
end
