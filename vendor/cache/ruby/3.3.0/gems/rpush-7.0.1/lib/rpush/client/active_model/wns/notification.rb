module Rpush
  module Client
    module ActiveModel
      module Wns
        module Notification
          WNS_PRIORITY_HIGH = 1
          WNS_PRIORITY_MEDIUM = 2
          WNS_PRIORITY_LOW = 3
          WNS_PRIORITY_VERY_LOW = 4

          WNS_PRIORITIES = [WNS_PRIORITY_HIGH, WNS_PRIORITY_MEDIUM, WNS_PRIORITY_LOW, WNS_PRIORITY_VERY_LOW]

          module InstanceMethods
            def alert=(value)
              return unless value
              data = self.data || {}
              data['title'] = value
              self.data = data
            end

            def skip_data_validation?
              false
            end
          end

          def self.included(base)
            base.instance_eval do
              include InstanceMethods

              validates :uri, presence: true
              validates :uri, format: { with: %r{https?://[\S]+} }
              validates :data, presence: true, unless: :skip_data_validation?
              validates :priority, inclusion: { in: WNS_PRIORITIES }, allow_nil: true
            end
          end
        end
      end
    end
  end
end
