# frozen_string_literal: true

module Rouge
  module Lexers
    class Diff < RegexLexer
      title 'diff'
      desc 'Lexes unified diffs or patches'

      tag 'diff'
      aliases 'patch', 'udiff'
      filenames '*.diff', '*.patch'
      mimetypes 'text/x-diff', 'text/x-patch'

      def self.detect?(text)
        return true if text.start_with?('Index: ')
        return true if text =~ %r(\Adiff[^\n]*?\ba/[^\n]*\bb/)
        return true if text =~ /---.*?\n[+][+][+]/ || text =~ /[+][+][+].*?\n---/
      end

      state :root do
        rule(/^ .*$\n?/, Text)
        rule(/^---$\n?/, Punctuation)

        rule %r(
          (^\++.*$\n?) |
          (^>+[ \t]+.*$\n?) |
          (^>+$\n?)
        )x, Generic::Inserted

        rule %r(
          (^-+.*$\n?) |
          (^<+[ \t]+.*$\n?) |
          (^<+$\n?)
        )x, Generic::Deleted

        rule(/^!.*$\n?/, Generic::Strong)
        rule(/^([Ii]ndex|diff).*$\n?/, Generic::Heading)
        rule(/^(@@[^@]*@@)([^\n]*\n)/) do
          groups Punctuation, Text
        end
        rule(/^\w.*$\n?/, Punctuation)
        rule(/^=.*$\n?/, Generic::Heading)
        rule(/.+$\n?/, Text)
      end
    end
  end
end
