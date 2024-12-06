module Rpush
  module Client
    module ActiveModel
      module Wpns
        module Notification
          module InstanceMethods
            def alert=(value)
              return unless value
              data = self.data || {}
              data['title'] = value
              self.data = data
            end
          end

          def self.included(base)
            base.instance_eval do
              include InstanceMethods

              validates :uri, presence: true
              validates :uri, format: { with: %r{https?://[\S]+} }
              validates :data, presence: true
            end
          end
        end
      end
    end
  end
end
