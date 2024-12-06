# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Class to extract event information from the resource
        class Event
          UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

          SAFE_MODE = 'safe'
          EXTENDED_MODE = 'extended'

          attr_reader :user_id

          def initialize(resource, mode)
            @resource = resource
            @mode = mode
            @user_id = nil
            @email = nil
            @username = nil

            extract if @resource
          end

          def to_h
            return @event if defined?(@event)

            @event = {}
            @event[:email] = @email if @email
            @event[:username] = @username if @username
            @event
          end

          private

          def extract
            @user_id = @resource.id

            case @mode
            when EXTENDED_MODE
              @email = @resource.email
              @username = @resource.username
            when SAFE_MODE
              @user_id = nil unless @user_id && @user_id.to_s =~ UUID_REGEX
            else
              Datadog.logger.warn(
                "Invalid automated user evenst mode: `#{@mode}`. "\
                              'Supported modes are: `safe` and `extended`.'
              )
            end
          end
        end
      end
    end
  end
end
