# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  class Token
    class << self
      attr_reader :name
      attr_reader :parent
      attr_reader :shortname

      def cache
        @cache ||= {}
      end

      def sub_tokens
        @sub_tokens ||= {}
      end

      def [](qualname)
        return qualname unless qualname.is_a? ::String

        Token.cache[qualname]
      end

      def inspect
        "<Token #{qualname}>"
      end

      def matches?(other)
        other.token_chain.include? self
      end

      def token_chain
        @token_chain ||= ancestors.take_while { |x| x != Token }.reverse
      end

      def qualname
        @qualname ||= token_chain.map(&:name).join('.')
      end

      def register!
        Token.cache[self.qualname] = self
        parent.sub_tokens[self.name] = self
      end

      def make_token(name, shortname, &b)
        parent = self
        Class.new(parent) do
          @parent = parent
          @name = name
          @shortname = shortname
          register!
          class_eval(&b) if b
        end
      end

      def token(name, shortname, &b)
        tok = make_token(name, shortname, &b)
        const_set(name, tok)
      end

      def each_token(&b)
        Token.cache.each do |(_, t)|
          b.call(t)
        end
      end
    end

    module Tokens
      def self.token(name, shortname, &b)
        tok = Token.make_token(name, shortname, &b)
        const_set(name, tok)
      end

      # XXX IMPORTANT XXX
      # For compatibility, this list must be kept in sync with
      # pygments.token.STANDARD_TYPES
      # please see https://github.com/jneen/rouge/wiki/List-of-tokens
      token :Text, '' do
        token :Whitespace, 'w'
      end

      token :Escape, 'esc'
      token :Error,  'err'
      token :Other,  'x'

      token :Keyword, 'k' do
        token :Constant,    'kc'
        token :Declaration, 'kd'
        token :Namespace,   'kn'
        token :Pseudo,      'kp'
        token :Reserved,    'kr'
        token :Type,        'kt'
        token :Variable,    'kv'
      end

      token :Name, 'n' do
        token :Attribute,    'na'
        token :Builtin,      'nb' do
          token :Pseudo,     'bp'
        end
        token :Class,        'nc'
        token :Constant,     'no'
        token :Decorator,    'nd'
        token :Entity,       'ni'
        token :Exception,    'ne'
        token :Function,     'nf' do
          token :Magic,      'fm'
        end
        token :Property,     'py'
        token :Label,        'nl'
        token :Namespace,    'nn'
        token :Other,        'nx'
        token :Tag,          'nt'
        token :Variable,     'nv' do
          token :Class,      'vc'
          token :Global,     'vg'
          token :Instance,   'vi'
          token :Magic,      'vm'
        end
      end

      token :Literal,      'l' do
        token :Date,       'ld'

        token :String,      's' do
          token :Affix,     'sa'
          token :Backtick,  'sb'
          token :Char,      'sc'
          token :Delimiter, 'dl'
          token :Doc,       'sd'
          token :Double,    's2'
          token :Escape,    'se'
          token :Heredoc,   'sh'
          token :Interpol,  'si'
          token :Other,     'sx'
          token :Regex,     'sr'
          token :Single,    's1'
          token :Symbol,    'ss'
        end

        token :Number,     'm' do
          token :Bin,      'mb'
          token :Float,    'mf'
          token :Hex,      'mh'
          token :Integer,  'mi' do
            token :Long,   'il'
          end
          token :Oct,      'mo'
          token :Other,    'mx'
        end
      end

      token :Operator, 'o' do
        token :Word,   'ow'
      end

      token :Punctuation, 'p' do
        token :Indicator, 'pi'
      end

      token :Comment,       'c' do
        token :Hashbang,    'ch'
        token :Doc,         'cd'
        token :Multiline,   'cm'
        token :Preproc,     'cp'
        token :PreprocFile, 'cpf'
        token :Single,      'c1'
        token :Special,     'cs'
      end

      token :Generic,      'g' do
        token :Deleted,    'gd'
        token :Emph,       'ge'
        token :Error,      'gr'
        token :Heading,    'gh'
        token :Inserted,   'gi'
        token :Output,     'go'
        token :Prompt,     'gp'
        token :Strong,     'gs'
        token :Subheading, 'gu'
        token :Traceback,  'gt'
        token :Lineno,     'gl'
      end

      # convenience
      Num = Literal::Number
      Str = Literal::String
    end
  end
end
