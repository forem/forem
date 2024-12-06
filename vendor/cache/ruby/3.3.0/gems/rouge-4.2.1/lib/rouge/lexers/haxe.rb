# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class Haxe < RegexLexer
      title "Haxe"
      desc "Haxe Cross-platform Toolkit (http://haxe.org)"

      tag 'haxe'
      aliases 'hx', 'haxe'
      filenames '*.hx'
      mimetypes 'text/haxe', 'text/x-haxe', 'text/x-hx'

      def self.detect?(text)
        return true if text.shebang? "haxe"
      end

      def self.keywords
        @keywords ||= Set.new %w(
          as break case cast catch class continue default do else enum false for
          function if import in interface macro new null override package private
          public return switch this throw true try untyped while
        )
      end

      def self.imports
        @imports ||= Set.new %w(
          package import using
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(
          abstract dynamic extern extends from implements inline static to
          typedef var
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          super trace inline build autoBuild enum
        )
      end

      def self.constants
        @constants ||= Set.new %w(true false null)
      end

      def self.builtins
        @builtins ||= %w(
          Void Dynamic Math Class Any Float Int UInt String StringTools Sys
          EReg isNaN parseFloat parseInt this Array Map Date DateTools Bool
          Lambda Reflect Std File FileSystem
        )
      end

      id = /[$a-zA-Z_][a-zA-Z0-9_]*/
      dotted_id = /[$a-zA-Z_][a-zA-Z0-9_.]*/

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :expr_start do
        mixin :comments_and_whitespace

        rule %r/#(?:if|elseif|else|end).*/, Comment::Preproc

        rule %r(~) do
          token Str::Regex
          goto :regex
        end

        rule %r/[{]/, Punctuation, :object

        rule %r//, Text, :pop!
      end

      state :namespace do
        mixin :comments_and_whitespace

        rule %r/
           (#{dotted_id})
           (\s+)(in|as)(\s+)
           (#{id})
         /x do
          groups(Name::Namespace, Text::Whitespace, Keyword, Text::Whitespace, Name)
        end

        rule %r/#{dotted_id}/, Name::Namespace

        rule(//) { pop! }
      end

      state :regex do
        rule %r(/) do
          token Str::Regex
          goto :regex_end
        end

        rule %r([^/]\n), Error, :pop!

        rule %r/\n/, Error, :pop!
        rule %r/\[\^/, Str::Escape, :regex_group
        rule %r/\[/, Str::Escape, :regex_group
        rule %r/\\./, Str::Escape
        rule %r{[(][?][:=<!]}, Str::Escape
        rule %r/[{][\d,]+[}]/, Str::Escape
        rule %r/[()?]/, Str::Escape
        rule %r/./, Str::Regex
      end

      state :regex_end do
        rule %r/[gim]+/, Str::Regex, :pop!
        rule(//) { pop! }
      end

      state :regex_group do
        # specially highlight / in a group to indicate that it doesn't
        # close the regex
        rule %r/\//, Str::Escape

        rule %r([^/]\n) do
          token Error
          pop! 2
        end

        rule %r/\]/, Str::Escape, :pop!
        rule %r/\\./, Str::Escape
        rule %r/./, Str::Regex
      end

      state :bad_regex do
        rule %r/[^\n]+/, Error, :pop!
      end

      state :root do
        rule %r/\n/, Text, :statement
        rule %r(\{), Punctuation, :expr_start
        
        mixin :comments_and_whitespace

        rule %r/@/, Name::Decorator, :metadata
        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >> | ==
               | != )x,
          Operator, :expr_start
        rule %r([-:<>+*%&|\^/!=]=?), Operator, :expr_start
        rule %r/[(\[,]/, Punctuation, :expr_start
        rule %r/;/, Punctuation, :statement
        rule %r/[)\]}.]/, Punctuation

        rule %r/[?]/ do
          token Punctuation
          push :ternary
          push :expr_start
        end

        rule id do |m|
          match = m[0]

          if self.class.imports.include?(match)
            token Keyword::Namespace
            push :namespace
          elsif self.class.keywords.include?(match)
            token Keyword
            push :expr_start
          elsif self.class.declarations.include?(match)
            token Keyword::Declaration
            push :expr_start
          elsif self.class.reserved.include?(match)
            token Keyword::Reserved
          elsif self.class.constants.include?(match)
            token Keyword::Constant
          elsif self.class.builtins.include?(match)
            token Name::Builtin
          else
            token Name::Other
          end
        end

        rule %r/\-?\d+\.\d+(?:[eE]\d+)?[fd]?/, Num::Float
        rule %r/0x\h+/, Num::Hex
        rule %r/\-?[0-9]+/, Num::Integer
        rule %r/"/, Str::Double, :str_double
        rule %r/'/, Str::Single, :str_single
      end

      # braced parts that aren't object literals
      state :statement do
        rule %r/(#{id})(\s*)(:)/ do
          groups Name::Label, Text, Punctuation
        end

        mixin :expr_start
      end

      # object literals
      state :object do
        mixin :comments_and_whitespace
        rule %r/[}]/ do
          token Punctuation
          goto :statement
        end

        rule %r/(#{id})(\s*)(:)/ do
          groups Name::Attribute, Text, Punctuation
          push :expr_start
        end

        rule %r/:/, Punctuation
        mixin :root
      end

      state :metadata do
        rule %r/(#{id})(\()?/ do |m|
          groups Name::Decorator, Punctuation
          pop! unless m[2]
        end
        rule %r/:#{id}(?:\.#{id})*/, Name::Decorator, :pop!
        rule %r/\)/, Name::Decorator, :pop!
        mixin :root
      end

      # ternary expressions, where <id>: is not a label!
      state :ternary do
        rule %r/:/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end

      state :str_double do
        mixin :str_escape
        rule %r/"/, Str::Double, :pop!
        rule %r/[^\\"]+/, Str::Double
      end

      state :str_single do
        mixin :str_escape
        rule %r/'/, Str::Single, :pop!
        rule %r/\$\$/, Str::Single
        rule %r/\$#{id}/, Str::Interpol
        rule %r/\$\{/, Str::Interpol, :str_interpol
        rule %r/[^\\$']+/, Str::Single
      end

      state :str_escape do
        rule %r/\\[\\tnr'"]/, Str::Escape
        rule %r/\\[0-7]{3}/, Str::Escape
        rule %r/\\x\h{2}/, Str::Escape
        rule %r/\\u\h{4}/, Str::Escape
        rule %r/\\u\{\h{1,6}\}/, Str::Escape
      end 

      state :str_interpol do
        rule %r/\}/, Str::Interpol, :pop!
        mixin :root
      end
    end
  end
end
