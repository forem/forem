require 'rolify'
require 'rails'

module Rolify
  class Railtie < Rails::Railtie
    initializer 'rolify.initialize' do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :extend, Rolify
      end
      
      config.before_initialize do
        ::Mongoid::Document.module_eval do
          def self.included(base)
            base.extend Rolify
          end
        end
      end if defined?(Mongoid)
    end
  end
end