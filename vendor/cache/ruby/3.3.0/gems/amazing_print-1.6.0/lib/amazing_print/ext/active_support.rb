# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module ActiveSupport
    def self.included(base)
      base.send :alias_method, :cast_without_active_support, :cast
      base.send :alias_method, :cast, :cast_with_active_support
    end

    def cast_with_active_support(object, type)
      cast = cast_without_active_support(object, type)
      if defined?(::ActiveSupport) && defined?(::HashWithIndifferentAccess)
        if (defined?(::ActiveSupport::TimeWithZone) && object.is_a?(::ActiveSupport::TimeWithZone)) || object.is_a?(::Date)
          cast = :active_support_time
        elsif object.is_a?(::HashWithIndifferentAccess)
          cast = :hash_with_indifferent_access
        end
      end
      cast
    end

    # Format ActiveSupport::TimeWithZone as standard Time.
    #------------------------------------------------------------------------------
    def awesome_active_support_time(object)
      colorize(object.inspect, :time)
    end

    # Format HashWithIndifferentAccess as standard Hash.
    #------------------------------------------------------------------------------
    def awesome_hash_with_indifferent_access(object)
      awesome_hash(object)
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::ActiveSupport
#
# Colorize Rails logs.
#
AmazingPrint.force_colors! colors: ActiveSupport::LogSubscriber.colorize_logging if defined?(ActiveSupport::LogSubscriber)
