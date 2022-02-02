class ProfileDecorator < ApplicationDecorator
  # Return a Hash of the profile fields that should be rendered for a given
  # display area, e.g. :left_sidebar
  def ui_attributes_for(area:)
    names = ProfileField.public_send(area).pluck(:attribute_name)
    data.slice(*names)
      .transform_keys { |k| label_for_attribute(k) }
      .select { |k, v| k.present? && v.present? }
  end

  def label_for_attribute(attr)
    ProfileField.find_by(attribute_name: attr)&.label
  end
end
