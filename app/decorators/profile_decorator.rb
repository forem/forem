class ProfileDecorator < ApplicationDecorator
  # Return a Hash of the profile fields that should be rendered for a given
  # display area, e.g. :left_sidebar
  def ui_attributes_for(area:)
    return {} if data.blank?

    fields = ProfileField.cached_display_area_fields(area)
    fields.transform_values { |attribute_name| data[attribute_name] }.compact_blank
  end
end
