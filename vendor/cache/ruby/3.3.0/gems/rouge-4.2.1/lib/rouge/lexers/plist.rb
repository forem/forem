# frozen_string_literal: true

module Rouge
  module Lexers
    class Plist < RegexLexer
      desc 'plist'
      tag 'plist'
      aliases 'plist'
      filenames '*.plist', '*.pbxproj'

      mimetypes 'text/x-plist', 'application/x-plist'

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
      end

      state :root do
        rule %r{//.*$}, Comment
        rule %r{/\*.+?\*/}m, Comment
        mixin :whitespace
        rule %r/{/, Punctuation, :dictionary
        rule %r/\(/, Punctuation, :array
        rule %r/"([^"\\]|\\.)*"/, Literal::String::Double
        rule %r/'([^'\\]|\\.)*'/, Literal::String::Single
        rule %r/</, Punctuation, :data
        rule %r{[\w$/:.-]+}, Literal
      end

      state :dictionary do
        mixin :root
        rule %r/[=;]/, Punctuation
        rule %r/}/, Punctuation, :pop!
      end

      state :array do
        mixin :root
        rule %r/[,]/, Punctuation
        rule %r/\)/, Punctuation, :pop!
      end

      state :data do
        rule %r/[\h\s]+/, Literal::Number::Hex
        rule %r/>/, Punctuation, :pop!
      end
    end
  end
end
