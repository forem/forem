# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# Based on/regexes mostly from Brandon Bennett's pygments-routerlexers:
# https://github.com/nemith/pygments-routerlexers

module Rouge
  module Lexers
    class CiscoIos < RegexLexer
      title 'Cisco IOS'
      desc 'Cisco IOS configuration lexer'
      tag 'cisco_ios'
      filenames '*.cfg'
      mimetypes 'text/x-cisco-conf'

      state :root do
        rule %r/^!.*/, Comment::Single

        rule %r/^(version\s+)(.*)$/ do
          groups Keyword, Num::Float
        end

        rule %r/(desc*r*i*p*t*i*o*n*)(.*?)$/ do
          groups Keyword, Comment::Single
        end

        rule %r/^(inte*r*f*a*c*e*|controller|router \S+|voice translation-\S+|voice-port|line)(.*)$/ do
          groups Keyword::Type, Name::Function
        end

        rule %r/(password|secret)(\s+[57]\s+)(\S+)/ do
          groups Keyword, Num, String::Double
        end

        rule %r/(permit|deny)/, Operator::Word

        rule %r/^(banner\s+)(motd\s+|login\s+)([#$%])/ do
          groups Keyword, Name::Function, Str::Delimiter
          push :cisco_ios_text
        end

        rule %r/^(dial-peer\s+\S+\s+)(\S+)(.*?)$/ do
          groups Keyword, Name::Attribute, Keyword
        end

        rule %r/^(vlan\s+)(\d+)$/ do
          groups Keyword, Name::Attribute
        end

        # IPv4 Address/Prefix
        rule %r/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/\d{1,2})?/, Num

        # NSAP
        rule %r/49\.\d{4}\.\d{4}\.\d{4}\.\d{4}\.\d{2}/, Num

        # MAC Address
        rule %r/[a-f0-9]{4}\.[a-f0-9]{4}\.[a-f0-9]{4}/, Num::Hex

        rule %r/^(\s*no\s+)(\S+)/ do
          groups Keyword::Constant, Keyword
        end

        rule %r/^[^\n\r]\s*\S+/, Keyword

        # Obfuscated Passwords
        rule  %r/\*+/, Name::Entity

        rule %r/(?<= )\d+(?= )/, Num

        # Newline catcher, avoid errors on empty lines
        rule %r/\n+/m, Text

        # This one goes last, a text catch-all
        rule %r/./, Text
      end

      state :cisco_ios_text do
        rule %r/[^#$%]/, Text
        rule %r/[#$%]/, Str::Delimiter, :pop!
      end
    end
  end
end
