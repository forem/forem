class ProfileDecorator < ApplicationDecorator
  # Return a Hash of the profile fields that should be rendered for a given
  # display area, e.g. :left_sidebar
  def ui_attributes_for(area:)
    fields = ProfileField.public_send(area).pluck(:label, :attribute_name).to_h
    fields.transform_values { |attribute_name| data[attribute_name] }.compact_blank
  end
end
