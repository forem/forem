# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Protobuf < RegexLexer
      title 'Protobuf'
      desc 'Google\'s language-neutral, platform-neutral, extensible mechanism for serializing structured data'
      tag 'protobuf'
      aliases 'proto'
      filenames '*.proto'
      mimetypes 'text/x-proto'

      kw = /\b(ctype|default|extensions|import|max|oneof|option|optional|packed|repeated|required|returns|rpc|to)\b/
      datatype = /\b(bool|bytes|double|fixed32|fixed64|float|int32|int64|sfixed32|sfixed64|sint32|sint64|string|uint32|uint64)\b/

      state :root do
        rule %r/[\s]+/, Text
        rule %r/[,;{}\[\]()]/, Punctuation
        rule %r/\/(\\\n)?\/($|(.|\n)*?[^\\]$)/, Comment::Single
        rule %r/\/(\\\n)?\*(.|\n)*?\*(\\\n)?\//, Comment::Multiline
        rule kw, Keyword
        rule datatype, Keyword::Type
        rule %r/true|false/, Keyword::Constant
        rule %r/(package)(\s+)/ do
          groups Keyword::Namespace, Text
          push :package
        end

        rule %r/(message|extend)(\s+)/ do
          groups Keyword::Declaration, Text
          push :message
        end

        rule %r/(enum|group|service)(\s+)/ do
          groups Keyword::Declaration, Text
          push :type
        end

        rule %r/".*?"/, Str
        rule %r/'.*?'/, Str
        rule %r/(\d+\.\d*|\.\d+|\d+)[eE][+-]?\d+[LlUu]*/, Num::Float
        rule %r/(\d+\.\d*|\.\d+|\d+[fF])[fF]?/, Num::Float
        rule %r/(\-?(inf|nan))\b/, Num::Float
        rule %r/0x[0-9a-fA-F]+[LlUu]*/, Num::Hex
        rule %r/0[0-7]+[LlUu]*/, Num::Oct
        rule %r/\d+[LlUu]*/, Num::Integer
        rule %r/[+-=]/, Operator
        rule %r/([a-zA-Z_][\w.]*)([ \t]*)(=)/ do
          groups Name::Attribute, Text, Operator
        end
        rule %r/[a-zA-Z_][\w.]*/, Name
      end

      state :package do
        rule %r/[a-zA-Z_]\w*/, Name::Namespace, :pop!
        rule(//) { pop! }
      end

      state :message do
        rule %r/[a-zA-Z_]\w*/, Name::Class, :pop!
        rule(//) { pop! }
      end

      state :type do
        rule %r/[a-zA-Z_]\w*/, Name, :pop!
        rule(//) { pop! }
      end
    end
  end
end
