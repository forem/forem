# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # shared states with SCSS
    class SassCommon < RegexLexer
      id = /[\w-]+/

      state :content_common do
        rule %r/@for\b/, Keyword, :for
        rule %r/@(debug|warn|if|each|while|else|return|media)/, Keyword, :value

        rule %r/(@mixin)(\s+)(#{id})/ do
          groups Keyword, Text, Name::Function
          push :value
        end

        rule %r/(@function)(\s+)(#{id})/ do
          groups Keyword, Text, Name::Function
          push :value
        end

        rule %r/@extend\b/, Keyword, :selector

        rule %r/(@include)(\s+)(#{id})/ do
          groups Keyword, Text, Name::Decorator
          push :value
        end

        rule %r/@#{id}/, Keyword, :selector
        rule %r/&/, Keyword, :selector

        # $variable: assignment
        rule %r/([$]#{id})([ \t]*)(:)/ do
          groups Name::Variable, Text, Punctuation
          push :value
        end
      end

      state :value do
        mixin :end_section
        rule %r/[ \t]+/, Text
        rule %r/[$]#{id}/, Name::Variable
        rule %r/url[(]/, Str::Other, :string_url
        rule %r/#{id}(?=\s*[(])/, Name::Function
        rule %r/%#{id}/, Name::Decorator

        # named literals
        rule %r/(true|false)\b/, Name::Builtin::Pseudo
        rule %r/(and|or|not)\b/, Operator::Word

        # colors and numbers
        rule %r/#[a-z0-9]{1,6}/i, Num::Hex
        rule %r/-?\d+(%|[a-z]+)?/, Num
        rule %r/-?\d*\.\d+(%|[a-z]+)?/, Num::Integer

        mixin :has_strings
        mixin :has_interp

        rule %r/[~^*!&%<>\|+=@:,.\/?-]+/, Operator
        rule %r/[\[\]()]+/, Punctuation
        rule %r(/[*]), Comment::Multiline, :inline_comment
        rule %r(//[^\n]*), Comment::Single

        # identifiers
        rule(id) do |m|
          if CSS.builtins.include? m[0]
            token Name::Builtin
          elsif CSS.constants.include? m[0]
            token Name::Constant
          else
            token Name
          end
        end
      end

      state :has_interp do
        rule %r/[#][{]/, Str::Interpol, :interpolation
      end

      state :has_strings do
        rule %r/"/, Str::Double, :dq
        rule %r/'/, Str::Single, :sq
      end

      state :interpolation do
        rule %r/}/, Str::Interpol, :pop!
        mixin :value
      end

      state :selector do
        mixin :end_section

        mixin :has_strings
        mixin :has_interp
        rule %r/[ \t]+/, Text
        rule %r/:/, Name::Decorator, :pseudo_class
        rule %r/[.]/, Name::Class, :class
        rule %r/#/, Name::Namespace, :id
        rule %r/%/, Name::Variable, :placeholder
        rule id, Name::Tag
        rule %r/&/, Keyword
        rule %r/[~^*!&\[\]()<>\|+=@:;,.\/?-]/, Operator
      end

      state :dq do
        rule %r/"/, Str::Double, :pop!
        mixin :has_interp
        rule %r/(\\.|#(?![{])|[^\n"#])+/, Str::Double
      end

      state :sq do
        rule %r/'/, Str::Single, :pop!
        mixin :has_interp
        rule %r/(\\.|#(?![{])|[^\n'#])+/, Str::Single
      end

      state :string_url do
        rule %r/[)]/, Str::Other, :pop!
        rule %r/(\\.|#(?![{])|[^\n)#])+/, Str::Other
        mixin :has_interp
      end

      state :selector_piece do
        mixin :has_interp
        rule(//) { pop! }
      end

      state :pseudo_class do
        rule id, Name::Decorator
        mixin :selector_piece
      end

      state :class do
        rule id, Name::Class
        mixin :selector_piece
      end

      state :id do
        rule id, Name::Namespace
        mixin :selector_piece
      end

      state :placeholder do
        rule id, Name::Variable
        mixin :selector_piece
      end

      state :for do
        rule %r/(from|to|through)/, Operator::Word
        mixin :value
      end

      state :attr_common do
        mixin :has_interp
        rule id do |m|
          if CSS.attributes.include? m[0]
            token Name::Label
          else
            token Name::Attribute
          end
        end
      end

      state :attribute do
        mixin :attr_common

        rule %r/([ \t]*)(:)/ do
          groups Text, Punctuation
          push :value
        end
      end

      state :inline_comment do
        rule %r/(\\#|#(?=[^\n{])|\*(?=[^\n\/])|[^\n#*])+/, Comment::Multiline
        mixin :has_interp
        rule %r([*]/), Comment::Multiline, :pop!
      end
    end
  end
end
