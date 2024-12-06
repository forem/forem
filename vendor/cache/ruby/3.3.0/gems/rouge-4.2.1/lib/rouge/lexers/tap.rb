# frozen_string_literal: true

module Rouge
  module Lexers
    class Tap < RegexLexer
      title 'TAP'
      desc 'Test Anything Protocol'
      tag 'tap'
      aliases 'tap'
      filenames '*.tap'

      mimetypes 'text/x-tap', 'application/x-tap'

      state :root do
        # A TAP version may be specified.
        rule %r/^TAP version \d+\n/, Name::Namespace

        # Specify a plan with a plan line.
        rule %r/^1\.\.\d+/, Keyword::Declaration, :plan

        # A test failure
        rule %r/^(not ok)([^\S\n]*)(\d*)/ do
          groups Generic::Error, Text, Literal::Number::Integer
          push :test
        end

        # A test success
        rule %r/^(ok)([^\S\n]*)(\d*)/ do
          groups Keyword::Reserved, Text, Literal::Number::Integer
          push :test
        end

        # Diagnostics start with a hash.
        rule %r/^#.*\n/, Comment

        # TAP's version of an abort statement.
        rule %r/^Bail out!.*\n/, Generic::Error

        # # TAP ignores any unrecognized lines.
        rule %r/^.*\n/, Text
      end

      state :plan do
        # Consume whitespace (but not newline).
        rule %r/[^\S\n]+/, Text

        # A plan may have a directive with it.
        rule %r/#/, Comment, :directive

        # Or it could just end.
        rule %r/\n/, Comment, :pop!

        # Anything else is wrong.
        rule %r/.*\n/, Generic::Error, :pop!
      end

      state :test do
        # Consume whitespace (but not newline).
        rule %r/[^\S\n]+/, Text

        # A test may have a directive with it.
        rule %r/#/, Comment, :directive

        rule %r/\S+/, Text

        rule %r/\n/, Text, :pop!
      end

      state :directive do
        # Consume whitespace (but not newline).
        rule %r/[^\S\n]+/, Comment

        # Extract todo items.
        rule %r/(?i)\bTODO\b/, Comment::Preproc

        # Extract skip items.
        rule %r/(?i)\bSKIP\S*/, Comment::Preproc

        rule %r/\S+/, Comment

        rule %r/\n/ do
          token Comment
          pop! 2
        end
      end
    end
  end
end
