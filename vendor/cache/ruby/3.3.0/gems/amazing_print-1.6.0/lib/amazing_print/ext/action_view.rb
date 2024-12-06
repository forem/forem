# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module ActionView
    # Use HTML colors and add default "debug_dump" class to the resulting HTML.
    def ap_debug(object, options = {})
      object.ai(
        options.merge(html: true)
      ).sub(
        /^<pre([\s>])/,
        '<pre class="debug_dump"\\1'
      ).html_safe
    end

    alias ap ap_debug
  end
end

ActionView::Base.include AmazingPrint::ActionView
