# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'sass/common.rb'

    class Scss < SassCommon
      title "SCSS"
      desc "SCSS stylesheets (sass-lang.com)"
      tag 'scss'
      filenames '*.scss'
      mimetypes 'text/x-scss'

      state :root do
        rule %r/\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/[*].*?[*]/)m, Comment::Multiline
        rule %r/@import\b/, Keyword, :value

        mixin :content_common

        rule(/(?=[^;{}][;}])/) { push :attribute }
        rule(/(?=[^;{}:\[]+:[^a-z])/) { push :attribute }

        rule(//) { push :selector }
      end

      state :end_section do
        rule %r/\n/, Text
        rule(/[;{}]/) { token Punctuation; reset_stack }
      end
    end
  end
end
