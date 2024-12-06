# frozen_string_literal: true

autoload :CGI, 'cgi'

require_relative 'colors'

module AmazingPrint
  module Colorize
    # Pick the color and apply it to the given string as necessary.
    #------------------------------------------------------------------------------
    def colorize(str, type)
      str = CGI.escapeHTML(str) if options[:html]
      return str if options[:plain] || !options[:color][type] || !inspector.colorize?

      AmazingPrint::Colors.public_send(options[:color][type], str, options[:html])
    end
  end
end
