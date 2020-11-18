class ProfileDecorator < ApplicationDecorator
  def ui_attributes_for(area:)
    # Return a Hash of the profile fields that should be rendered for a given
    # display area, e.g. :left_sidebar
    names = ProfileField.public_send(area).pluck(:attribute_name)
    data.slice(*names).reject { |_, v| v.blank? }
  end
end
