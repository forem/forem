require "rails/railtie"
require "pathname"

module CypressRails
  class Railtie < Rails::Railtie
    railtie_name :"cypress-rails"

    rake_tasks do
      load Pathname.new(__dir__).join("rake.rb")
    end
  end
end
