# -*- coding: utf-8 -*- #
# frozen_string_literal: true

require 'yaml'

module Rouge
  module Lexers
    class Lasso < TemplateLexer
      title "Lasso"
      desc "The Lasso programming language (lassosoft.com)"
      tag 'lasso'
      aliases 'lassoscript'
      filenames '*.lasso', '*.lasso[89]'
      mimetypes 'text/x-lasso', 'text/html+lasso', 'application/x-httpd-lasso'

      option :start_inline, 'Whether to start inline instead of requiring <?lasso or ['

      def self.detect?(text)
        return true if text.shebang?('lasso9')
        return true if text =~ /\A.*?<\?(lasso(script)?|=)/
      end

      def initialize(*)
        super

        @start_inline = bool_option(:start_inline)
      end

      def start_inline?
        @start_inline
      end

      start do
        push :lasso if start_inline?
      end

      # self-modifying method that loads the keywords file
      def self.keywords
        Kernel::load File.join(Lexers::BASE_DIR, 'lasso/keywords.rb')
        keywords
      end

      id = /[a-z_][\w.]*/i

      state :root do
        rule %r/^#![ \S]+lasso9\b/, Comment::Preproc, :lasso
        rule(/(?=\[|<)/) { push :delimiters }
        rule %r/\s+/, Text::Whitespace
        rule(//) { push :delimiters; push :lassofile }
      end

      state :delimiters do
        rule %r/\[no_square_brackets\]/, Comment::Preproc, :nosquarebrackets
        rule %r/\[noprocess\]/, Comment::Preproc, :noprocess
        rule %r/\[/, Comment::Preproc, :squarebrackets
        rule %r/<\?(lasso(script)?|=)/i, Comment::Preproc, :anglebrackets
        rule(/([^\[<]|<!--.*?-->|<(script|style).*?\2>|<(?!\?(lasso(script)?|=)))+/im) { delegate parent }
      end

      state :nosquarebrackets do
        rule %r/\[noprocess\]/, Comment::Preproc, :noprocess
        rule %r/<\?(lasso(script)?|=)/i, Comment::Preproc, :anglebrackets
        rule(/([^\[<]|<!--.*?-->|<(script|style).*?\2>|<(?!\?(lasso(script)?|=))|\[(?!noprocess))+/im) { delegate parent }
      end

      state :noprocess do
        rule %r(\[/noprocess\]), Comment::Preproc, :pop!
        rule(%r(([^\[]|\[(?!/noprocess))+)i) { delegate parent }
      end

      state :squarebrackets do
        rule %r/\]/, Comment::Preproc, :pop!
        mixin :lasso
      end

      state :anglebrackets do
        rule %r/\?>/, Comment::Preproc, :pop!
        mixin :lasso
      end

      state :lassofile do
        rule %r/\]|\?>/, Comment::Preproc, :pop!
        mixin :lasso
      end

      state :whitespacecomments do
        rule %r/\s+/, Text
        rule %r(//.*?\n), Comment::Single
        rule %r(/\*\*!.*?\*/)m, Comment::Doc
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :lasso do
        mixin :whitespacecomments

        # literals
        rule %r/\d*\.\d+(e[+-]?\d+)?/i, Num::Float
        rule %r/0x[\da-f]+/i, Num::Hex
        rule %r/\d+/, Num::Integer
        rule %r/(infinity|NaN)\b/i, Num
        rule %r/'[^'\\]*(\\.[^'\\]*)*'/m, Str::Single
        rule %r/"[^"\\]*(\\.[^"\\]*)*"/m, Str::Double
        rule %r/`[^`]*`/m, Str::Backtick

        # names
        rule %r/\$#{id}/, Name::Variable
        rule %r/#(#{id}|\d+\b)/, Name::Variable::Instance
        rule %r/(\.\s*)('#{id}')/ do
          groups Name::Builtin::Pseudo, Name::Variable::Class
        end
        rule %r/(self)(\s*->\s*)('#{id}')/i do
          groups Name::Builtin::Pseudo, Operator, Name::Variable::Class
        end
        rule %r/(\.\.?\s*)(#{id}(=(?!=))?)/ do
          groups Name::Builtin::Pseudo, Name::Other
        end
        rule %r/(->\\?\s*|&\s*)(#{id}(=(?!=))?)/ do
          groups Operator, Name::Other
        end
        rule %r/(?<!->)(self|inherited|currentcapture|givenblock)\b/i, Name::Builtin::Pseudo
        rule %r/-(?!infinity)#{id}/i, Name::Attribute
        rule %r/::\s*#{id}/, Name::Label

        # definitions
        rule %r/(define)(\s+)(#{id})(\s*=>\s*)(type|trait|thread)\b/i do
          groups Keyword::Declaration, Text, Name::Class, Operator, Keyword
        end
        rule %r((define)(\s+)(#{id})(\s*->\s*)(#{id}=?|[-+*/%]))i do
          groups Keyword::Declaration, Text, Name::Class, Operator, Name::Function
          push :signature
        end
        rule %r/(define)(\s+)(#{id})/i do
          groups Keyword::Declaration, Text, Name::Function
          push :signature
        end
        rule %r((public|protected|private|provide)(\s+)((#{id}=?|[-+*/%])(?=\s*\()))i do
          groups Keyword, Text, Name::Function
          push :signature
        end
        rule %r/(public|protected|private|provide)(\s+)(#{id})/i do
          groups Keyword, Text, Name::Function
        end

        # keywords
        rule %r/(true|false|none|minimal|full|all|void)\b/i, Keyword::Constant
        rule %r/(local|var|variable|global|data(?=\s))\b/i, Keyword::Declaration
        rule %r/(#{id})(\s+)(in)\b/i do
          groups Name, Text, Keyword
        end
        rule %r/(let|into)(\s+)(#{id})/i do
          groups Keyword, Text, Name
        end

        # other
        rule %r/,/, Punctuation, :commamember
        rule %r/(and|or|not)\b/i, Operator::Word
        rule %r/(#{id})(\s*::\s*#{id})?(\s*=(?!=|>))/ do
          groups Name, Name::Label, Operator
        end

        rule %r((/?)([\w.]+)) do |m|
          name = m[2].downcase

          if m[1] != ''
            token Punctuation, m[1]
          end

          if name == 'namespace_using'
            token Keyword::Namespace, m[2]
          elsif self.class.keywords[:exceptions].include? name
            token Name::Exception, m[2]
          elsif self.class.keywords[:types].include? name
            token Keyword::Type, m[2]
          elsif self.class.keywords[:traits].include? name
            token Name::Decorator, m[2]
          elsif self.class.keywords[:keywords].include? name
            token Keyword, m[2]
          elsif self.class.keywords[:builtins].include? name
            token Name::Builtin, m[2]
          else
            token Name::Other, m[2]
          end
        end

        rule %r/(=)(n?bw|n?ew|n?cn|lte?|gte?|n?eq|n?rx|ft)\b/i do
          groups Operator, Operator::Word
        end
        rule %r(:=|[-+*/%=<>&|!?\\]+), Operator
        rule %r/[{}():;,@^]/, Punctuation
      end

      state :signature do
        rule %r/\=>/, Operator, :pop!
        rule %r/\)/, Punctuation, :pop!
        rule %r/[(,]/, Punctuation, :parameter
        mixin :lasso
      end

      state :parameter do
        rule %r/\)/, Punctuation, :pop!
        rule %r/-?#{id}/, Name::Attribute, :pop!
        rule %r/\.\.\./, Name::Builtin::Pseudo
        mixin :lasso
      end

      state :commamember do
        rule %r((#{id}=?|[-+*/%])(?=\s*(\(([^()]*\([^()]*\))*[^\)]*\)\s*)?(::[\w.\s]+)?=>)), Name::Function, :signature
        mixin :whitespacecomments
        rule %r//, Text, :pop!
      end

    end
  end
end
