# frozen_string_literal: true

require 'yaml'

module Rouge
  module Lexers
    class Apache < RegexLexer
      title "Apache"
      desc 'configuration files for Apache web server'
      tag 'apache'
      mimetypes 'text/x-httpd-conf', 'text/x-apache-conf'
      filenames '.htaccess', 'httpd.conf'

      # self-modifying method that loads the keywords file
      def self.directives
        Kernel::load File.join(Lexers::BASE_DIR, 'apache/keywords.rb')
        directives
      end

      def self.sections
        Kernel::load File.join(Lexers::BASE_DIR, 'apache/keywords.rb')
        sections
      end

      def self.values
        Kernel::load File.join(Lexers::BASE_DIR, 'apache/keywords.rb')
        values
      end

      def name_for_token(token, tktype)
        if self.class.sections.include? token
          tktype
        elsif self.class.directives.include? token
          tktype
        elsif self.class.values.include? token
          tktype
        else
          Text
        end
      end

      state :whitespace do
        rule %r/\#.*/, Comment
        rule %r/\s+/m, Text
      end

      state :root do
        mixin :whitespace

        rule %r/(<\/?)(\w+)/ do |m|
          groups Punctuation, name_for_token(m[2].downcase, Name::Label)
          push :section
        end

        rule %r/\w+/ do |m|
          token name_for_token(m[0].downcase, Name::Class)
          push :directive
        end
      end

      state :section do
        # Match section arguments
        rule %r/([^>]+)?(>(?:\r\n?|\n)?)/ do
          groups Literal::String::Regex, Punctuation
          pop!
        end

        mixin :whitespace
      end

      state :directive do
        # Match value literals and other directive arguments
        rule %r/\r\n?|\n/, Text, :pop!

        mixin :whitespace

        rule %r/\S+/ do |m|
          token name_for_token(m[0].downcase, Literal::String::Symbol)
        end
      end
    end
  end
end
