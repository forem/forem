# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class Velocity < TemplateLexer
      title 'Velocity'
      desc 'Velocity is a Java-based template engine (velocity.apache.org)'
      tag 'velocity'
      filenames '*.vm', '*.velocity', '*.fhtml'
      mimetypes 'text/html+velocity'

      id = /[a-z_]\w*/i

      state :root do
        rule %r/[^{#$]+/ do
          delegate parent
        end

        rule %r/(#)(\*.*?\*)(#)/m, Comment::Multiline
        rule %r/(##)(.*?$)/, Comment::Single

        rule %r/(#\{?)(#{id})(\}?)(\s?\()/m do
          groups Punctuation, Name::Function, Punctuation, Punctuation
          push :directive_params
        end

        rule %r/(#\{?)(#{id})(\}|\b)/m do
          groups Punctuation, Name::Function, Punctuation
        end

        rule %r/\$\{?/, Punctuation, :variable
      end

      state :variable do
        rule %r/#{id}/, Name::Variable
        rule %r/\(/, Punctuation, :func_params
        rule %r/(\.)(#{id})/ do
          groups Punctuation, Name::Variable
        end
        rule %r/\}/, Punctuation, :pop!
        rule(//) { pop! }
      end

      state :directive_params do
        rule %r/(&&|\|\||==?|!=?|[-<>+*%&|^\/])|\b(eq|ne|gt|lt|ge|le|not|in)\b/, Operator
        rule %r/\[/, Operator, :range_operator
        rule %r/\b#{id}\b/, Name::Function
        mixin :func_params
      end

      state :range_operator do
        rule %r/[.]{2}/, Operator
        mixin :func_params
        rule %r/\]/, Operator, :pop!
      end

      state :func_params do
        rule %r/\$\{?/, Punctuation, :variable
        rule %r/\s+/, Text
        rule %r/,/, Punctuation
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Double
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Single
        rule %r/0[xX][0-9a-fA-F]+[Ll]?/, Num::Hex
        rule %r/\b[0-9]+\b/, Num::Integer
        rule %r/(true|false|null)\b/, Keyword::Constant
        rule %r/[(\[]/, Punctuation, :push
        rule %r/[)\]}]/, Punctuation, :pop!
      end
    end
  end
end
