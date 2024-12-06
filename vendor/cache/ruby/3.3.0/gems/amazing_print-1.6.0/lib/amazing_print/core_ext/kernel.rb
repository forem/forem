# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module Kernel
  def ai(options = {})
    ap = AmazingPrint::Inspector.new(options)
    awesome = ap.awesome self
    if options[:html]
      awesome = "<pre>#{awesome}</pre>"
      awesome = awesome.html_safe if defined? ActiveSupport
    end
    awesome
  end
  alias awesome_inspect ai

  def ap(object, options = {})
    puts object.ai(options)
    object unless AmazingPrint.console?
  end
  alias amazing_print ap

  module_function :ap
end
