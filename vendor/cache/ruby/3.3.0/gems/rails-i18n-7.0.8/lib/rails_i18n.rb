module RailsI18n
  def self.enabled_modules
    @enabled_modules ||= Set.new
  end

  def self.enabled_modules=(other)
    @enabled_modules = Set.new(other)
  end
end

require 'rails_i18n/railtie'
