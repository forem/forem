# frozen_string_literal: true

require 'rails/railtie'

class Railtie < Rails::Railtie
  initializer 'fast_jsonapi.active_record' do
    ActiveSupport.on_load :active_record do
      require 'extensions/has_one'
    end
  end
end
