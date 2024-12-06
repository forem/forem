# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  class TextAnalyzer < String
    # Find a shebang.  Returns nil if no shebang is present.
    def shebang
      return @shebang if instance_variable_defined? :@shebang

      self =~ /\A\s*#!(.*)$/
      @shebang = $1
    end

    # Check if the given shebang is present.
    #
    # This normalizes things so that `text.shebang?('bash')` will detect
    # `#!/bash`, '#!/bin/bash', '#!/usr/bin/env bash', and '#!/bin/bash -x'
    def shebang?(match)
      return false unless shebang
      match = /\b#{match}(\s|$)/
      match === shebang
    end

    # Return the contents of the doctype tag if present, nil otherwise.
    def doctype
      return @doctype if instance_variable_defined? :@doctype

      self =~ %r(\A\s*
        (?:<\?.*?\?>\s*)? # possible <?xml...?> tag
        <!DOCTYPE\s+(.+?)>
      )xm
      @doctype = $1
    end

    # Check if the doctype matches a given regexp or string
    def doctype?(type=//)
      type === doctype
    end

    # Return true if the result of lexing with the given lexer contains no
    # error tokens.
    def lexes_cleanly?(lexer)
      lexer.lex(self) do |(tok, _)|
        return false if tok.name == 'Error'
      end

      true
    end
  end
end
