# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Sieve < RegexLexer
      title "Sieve"
      desc "mail filtering language"

      tag 'sieve'
      filenames '*.sieve'

      id = /:?[a-zA-Z_][a-zA-Z0-9_]*/

      # control commands (rfc5228 § 3)
      def self.controls
        @controls ||= %w(if elsif else require stop)
      end

      def self.actions
        @actions ||= Set.new(
          # action commands (rfc5228 § 2.9)
          %w(keep fileinto redirect discard) +
          # Editheader Extension (rfc5293)
          %w(addheader deleteheader) +
          # Reject and Extended Reject Extensions (rfc5429)
          %w(reject ereject) +
          # Extension for Notifications (rfc5435)
          %w(notify) +
          # Imap4flags Extension (rfc5232)
          %w(setflag addflag removeflag) +
          # Vacation Extension (rfc5230)
          %w(vacation) +
          # MIME Part Tests, Iteration, Extraction, Replacement, and Enclosure (rfc5703)
          %w(replace enclose extracttext)
        )
      end

      def self.tests
        @tests ||= Set.new(
          # test commands (rfc5228 § 5)
          %w(address allof anyof exists false header not size true) +
          # Body Extension (rfc5173)
          %w(body) +
          # Imap4flags Extension (rfc5232)
          %w(hasflag) +
          # Spamtest and Virustest Extensions (rfc5235)
          %w(spamtest virustest) +
          # Date and Index Extensions (rfc5260)
          %w(date currentdate) +
          # Extension for Notifications (rfc5435)
          %w(valid_notify_method notify_method_capability) +
          # Extensions for Checking Mailbox Status and Accessing Mailbox
          # Metadata (rfc5490)
          %w(mailboxexists metadata metadataexists servermetadata servermetadataexists)
        )
      end

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(#.*), Comment::Single
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :string do
        rule %r/\\./, Str::Escape
        rule %r/"/, Str::Double, :pop!
        # Variables Extension (rfc5229)
        rule %r/\${(?:[0-9][.0-9]*|[a-zA-Z_][.a-zA-Z0-9_]*)}/, Str::Interpol
        rule %r/./, Str::Double
      end

      state :root do
        mixin :comments_and_whitespace

        rule %r/[\[\](),;{}]/, Punctuation

        rule id do |m|
          if self.class.controls.include? m[0]
            token Keyword
          elsif self.class.tests.include? m[0]
            token Name::Variable
          elsif self.class.actions.include? m[0]
            token Name::Function
          elsif m[0] =~ /^:/ # tags like :contains, :matches etc.
            token Operator
          else
            token Name::Other
          end
        end

        rule %r/"/, Str::Double, :string
        rule %r/[0-9]+[KMG]/, Num::Integer
      end
    end
  end
end
