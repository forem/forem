# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module Logger
    # Add ap method to logger
    #------------------------------------------------------------------------------
    def ap(object, options = {})
      if options.is_a?(Hash)
        level = options.delete(:level)
      else
        level = options
        options = {}
      end

      level ||= AmazingPrint.defaults[:log_level] if AmazingPrint.defaults
      level ||= :debug
      send level, object.ai(options)
    end
  end
end

Logger.include AmazingPrint::Logger
ActiveSupport::BufferedLogger.include AmazingPrint::Logger if defined?(ActiveSupport::BufferedLogger)
