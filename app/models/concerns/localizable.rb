module Localizable
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers

  # i18n path utilities
  def locale_prefix(locale = nil)
    locale || I18n.locale != I18n.default_locale ? root_path(locale: locale || I18n.locale) : ""
  end

  def path(locale = nil, raw: false)
    raw_path = read_attribute(:path) || (respond_to?(:unlocalized_path) ? unlocalized_path : nil)
    raw_path ? "#{locale_prefix locale unless raw}#{raw_path}" : nil
  end
end
