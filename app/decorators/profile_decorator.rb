class ProfileDecorator < ApplicationDecorator
  DEV_HEADER_FIELDS = %w[employment_title employer_name].freeze

  def ui_attributes_for(area:)
    # Return a Hash of the profile fields that should be rendered for a given
    # display area, e.g. :left_sidebar
    names = ProfileField.public_send(area).pluck(:attribute_name)
    # Temporary workaround: DEV specific header fields are hardcoded in the view
    if SiteConfig.dev_to?
      names -= DEV_HEADER_FIELDS
    end
    data.slice(*names).select { |_, v| v.present? }
  end
end
