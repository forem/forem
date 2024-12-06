# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'c.rb'

    class Cpp < C
      title "C++"
      desc "The C++ programming language"

      tag 'cpp'
      aliases 'c++'
      # the many varied filenames of c++ source files...
      filenames '*.cpp', '*.hpp',
                '*.c++', '*.h++',
                '*.cc',  '*.hh',
                '*.cxx', '*.hxx',
                '*.pde', '*.ino',
                '*.tpp', '*.h'
      mimetypes 'text/x-c++hdr', 'text/x-c++src'

      def self.keywords
        @keywords ||= super + Set.new(%w(
          asm auto catch char8_t concept
          consteval constexpr constinit const_cast co_await co_return co_yield
          delete dynamic_cast explicit export friend
          mutable namespace new operator private protected public
          reinterpret_cast requires restrict size_of static_cast this throw throws
          typeid typename using virtual final override import module

          alignas alignof decltype noexcept static_assert
          thread_local try
        ))
      end

      def self.keywords_type
        @keywords_type ||= super + Set.new(%w(
          bool
        ))
      end

      def self.reserved
        @reserved ||= super + Set.new(%w(
          __virtual_inheritance __uuidof __super __single_inheritance
          __multiple_inheritance __interface __event
        ))
      end

      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      prepend :root do
        # Offload C++ extensions, http://offload.codeplay.com/
        rule %r/(?:__offload|__blockingoffload|__outer)\b/, Keyword::Pseudo
      end

      # digits with optional inner quotes
      # see www.open-std.org/jtc1/sc22/wg21/docs/papers/2013/n3781.pdf
      dq = /\d('?\d)*/

      prepend :statements do
        rule %r/(class|struct)\b/, Keyword, :classname
        rule %r/template\b/, Keyword, :template
        rule %r/#{dq}(\.#{dq})?(?:y|d|h|(?:min)|s|(?:ms)|(?:us)|(?:ns)|i|(?:if)|(?:il))\b/, Num::Other
        rule %r((#{dq}[.]#{dq}?|[.]#{dq})(e[+-]?#{dq}[lu]*)?)i, Num::Float
        rule %r(#{dq}e[+-]?#{dq}[lu]*)i, Num::Float
        rule %r/0x\h('?\h)*[lu]*/i, Num::Hex
        rule %r/0b[01]+('[01]+)*/, Num::Bin
        rule %r/0[0-7]('?[0-7])*[lu]*/i, Num::Oct
        rule %r/#{dq}[lu]*/i, Num::Integer
        rule %r/\bnullptr\b/, Name::Builtin
        rule %r/(?:u8|u|U|L)?R"([a-zA-Z0-9_{}\[\]#<>%:;.?*\+\-\/\^&|~!=,"']{,16})\(.*?\)\1"/m, Str
        rule %r/(::|<=>)/, Operator
        rule %r/[{]/, Punctuation
        rule %r/}/ do
          token Punctuation
          pop! if in_state?(:function) # pop :function
        end
      end

      state :classname do
        rule id, Name::Class, :pop!

        # template specification
        mixin :whitespace
        rule %r/[.]{3}/, Operator
        rule %r/,/, Punctuation, :pop!
        rule(//) { pop! }
      end

      state :template do
        rule %r/[>;]/, Punctuation, :pop!
        rule %r/typename\b/, Keyword, :classname
        mixin :statements
      end

      state :case do
        rule %r/:(?!:)/, Punctuation, :pop!
        mixin :statements
      end
    end
  end
end
