# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# Adapted from pygments PostScriptLexer
module Rouge
  module Lexers
    class PostScript < RegexLexer
      title "PostScript"
      desc "The PostScript language (adobe.com/devnet/postscript.html)"
      tag "postscript"
      aliases "postscr", "postscript", "ps", "eps"
      filenames "*.ps", "*.eps"
      mimetypes "application/postscript"

      def self.detect?(text)
        return true if /^%!/ =~ text
      end

      delimiter = %s"()<>\[\]{}/%\s"
      delimiter_end = Regexp.new("(?=[#{delimiter}])")
      valid_name_chars = Regexp.new("[^#{delimiter}]")
      valid_name = /#{valid_name_chars}+#{delimiter_end}/

      # These keywords taken from
      # <http://www.math.ubc.ca/~cass/graphics/manual/pdf/a1.pdf>
      # Is there an authoritative list anywhere that doesn't involve
      # trawling documentation?
      keywords = %w/abs add aload arc arcn array atan begin
        bind ceiling charpath clip closepath concat
        concatmatrix copy cos currentlinewidth currentmatrix
        currentpoint curveto cvi cvs def defaultmatrix
        dict dictstackoverflow div dtransform dup end
        exch exec exit exp fill findfont floor get
        getinterval grestore gsave identmatrix idiv
        idtransform index invertmatrix itransform length
        lineto ln load log loop matrix mod moveto
        mul neg newpath pathforall pathbbox pop print
        pstack put quit rand rangecheck rcurveto repeat
        restore rlineto rmoveto roll rotate round run
        save scale scalefont setdash setfont setgray
        setlinecap setlinejoin setlinewidth setmatrix
        setrgbcolor shfill show showpage sin sqrt
        stack stringwidth stroke strokepath sub syntaxerror
        transform translate truncate typecheck undefined
        undefinedfilename undefinedresult/

      state :root do
        # All comment types
        rule %r'^%!.+?$', Comment::Preproc
        rule %r'%%.*?$', Comment::Special
        rule %r'(^%.*?$){2,}', Comment::Multiline
        rule %r'%.*?$', Comment::Single

        # String literals are awkward; enter separate state.
        rule %r'\(', Str, :stringliteral

        # References
        rule %r'/#{valid_name}', Name::Variable

        rule %r'[{}<>\[\]]', Punctuation

        rule %r'(?:#{keywords.join('|')})#{delimiter_end}', Name::Builtin

        # Conditionals / flow control
        rule %r'(eq|ne|g[et]|l[et]|and|or|not|if(?:else)?|for(?:all)?)#{delimiter_end}', Keyword::Reserved
        rule %r'(false|true)#{delimiter_end}', Keyword::Constant

        # Numbers
        rule %r'<[0-9A-Fa-f]+>#{delimiter_end}', Num::Hex
        # Slight abuse: use Oct to signify any explicit base system
        rule %r'[0-9]+\#(\-|\+)?([0-9]+\.?|[0-9]*\.[0-9]+|[0-9]+\.[0-9]*)((e|E)[0-9]+)?#{delimiter_end}', Num::Oct
        rule %r'(\-|\+)?([0-9]+\.?|[0-9]*\.[0-9]+|[0-9]+\.[0-9]*)((e|E)[0-9]+)?#{delimiter_end}', Num::Float
        rule %r'(\-|\+)?[0-9]+#{delimiter_end}', Num::Integer

        # Names
        rule valid_name, Name::Function      # Anything else is executed

        rule %r'\s+', Text
      end

      state :stringliteral do
        rule %r'[^()\\]+', Str
        rule %r'\\', Str::Escape, :escape
        rule %r'\(', Str, :stringliteral
        rule %r'\)', Str, :pop!
      end

      state :escape do
        rule %r'[0-8]{3}|n|r|t|b|f|\\|\(|\)', Str::Escape, :pop!
      end
    end
  end
end
