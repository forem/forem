module DataUpdateScripts
  class SetProperDisplayAreaForProfileFields
    def run
      ProfileField.where.not(attribute_name: %w[brand_color1 brand_color2]).update_all(display_area: 0)
      ProfileField.where(attribute_name:
        %w[currently_hacking_on currently_learning mostly_work_with available_for]).
        update_all(display_area: 1)
    end
  end
end
