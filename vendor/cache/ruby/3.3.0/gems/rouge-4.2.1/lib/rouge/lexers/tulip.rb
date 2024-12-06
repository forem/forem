# frozen_string_literal: true

module Rouge
  module Lexers
    class Tulip < RegexLexer
      desc 'the tulip programming language (twitter.com/tuliplang)'
      tag 'tulip'
      aliases 'tulip'

      filenames '*.tlp'

      mimetypes 'text/x-tulip', 'application/x-tulip'

      def self.detect?(text)
        return true if text.shebang? 'tulip'
      end

      id = /[a-z][\w-]*/i
      upper_id = /[A-Z][\w-]*/

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r/#.*?$/, Comment
      end

      state :root do
        mixin :comments_and_whitespace

        rule %r/@#{id}/, Keyword


        rule %r/(\\#{id})([{])/ do
          groups Name::Function, Str
          push :nested_string
        end

        rule %r/([+]#{id})([{])/ do
          groups Name::Decorator, Str
          push :nested_string
        end

        rule %r/\\#{id}/, Name::Function
        rule %r/[+]#{id}/, Name::Decorator

        rule %r/"[{]/, Str, :dqi
        rule %r/"/, Str, :dq

        rule %r/'{/, Str, :nested_string
        rule %r/'#{id}/, Str

        rule %r/[.]#{id}/, Name::Tag
        rule %r/[$]#{id}?/, Name::Variable
        rule %r/-#{id}:?/, Name::Label
        rule %r/%#{id}/, Name::Function
        rule %r/`#{id}/, Operator::Word

        rule %r/[?~%._>,!\[\]:{}()=;\/-]/, Punctuation

        rule %r/[0-9]+([.][0-9]+)?/, Num

        rule %r/#{id}/, Name

        rule %r/</, Comment::Preproc, :angle_brackets
      end

      state :dq do
        rule %r/[^\\"]+/, Str
        rule %r/"/, Str, :pop!
        rule %r/\\./, Str::Escape
      end

      state :dqi do
        rule %r/[$][(]/, Str::Interpol, :interp_root
        rule %r/[{]/, Str, :dqi
        rule %r/[}]/, Str, :pop!
        rule %r/[^{}$]+/, Str
        rule %r/./, Str
      end

      state :interp_root do
        rule %r/[)]/, Str::Interpol, :pop!
        mixin :interp
      end

      state :interp do
        rule %r/[(]/, Punctuation, :interp
        rule %r/[)]/, Punctuation, :pop!
        mixin :root
      end

      state :nested_string do
        rule %r/\\./, Str::Escape
        rule(/{/) { token Str; push :nested_string }
        rule(/}/) { token Str; pop! }
        rule(/[^{}\\]+/) { token Str }
      end

      state :angle_brackets do
        mixin :comments_and_whitespace
        rule %r/>/, Comment::Preproc, :pop!
        rule %r/[*:]/, Punctuation
        rule %r/#{upper_id}/, Keyword::Type
        rule %r/#{id}/, Name::Variable
      end
    end
  end
end
