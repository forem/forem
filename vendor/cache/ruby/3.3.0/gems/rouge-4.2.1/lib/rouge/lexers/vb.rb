# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class VisualBasic < RegexLexer
      title "Visual Basic"
      desc "Visual Basic"
      tag 'vb'
      aliases 'visualbasic'
      filenames '*.vbs', '*.vb'
      mimetypes 'text/x-visualbasic', 'application/x-visualbasic'

      def self.keywords
        @keywords ||= Set.new %w(
          AddHandler Alias ByRef ByVal CBool CByte CChar CDate CDbl CDec
          CInt CLng CObj CSByte CShort CSng CStr CType CUInt CULng CUShort
          Call Case Catch Class Const Continue Declare Default Delegate
          Dim DirectCast Do Each Else ElseIf End EndIf Enum Erase Error
          Event Exit False Finally For Friend Function Get Global GoSub
          GoTo Handles If Implements Imports Inherits Interface Let
          Lib Loop Me Module MustInherit MustOverride MyBase MyClass
          Namespace Narrowing New Next Not NotInheritable NotOverridable
          Nothing Of On Operator Option Optional Overloads Overridable
          Overrides ParamArray Partial Private Property Protected Public
          RaiseEvent ReDim ReadOnly RemoveHandler Resume Return Select Set
          Shadows Shared Single Static Step Stop Structure Sub SyncLock
          Then Throw To True Try TryCast Using Wend When While Widening
          With WithEvents WriteOnly
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          Boolean Byte Char Date Decimal Double Integer Long Object
          SByte Short Single String Variant UInteger ULong UShort
        )
      end

      def self.operator_words
        @operator_words ||= Set.new %w(
          AddressOf And AndAlso As GetType In Is IsNot Like Mod Or OrElse
          TypeOf Xor
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          Console ConsoleColor
        )
      end

      id = /[a-z_]\w*/i
      upper_id = /[A-Z]\w*/

      state :whitespace do
        rule %r/\s+/, Text
        rule %r/\n/, Text, :bol
        rule %r/rem\b.*?$/i, Comment::Single
        rule %r(%\{.*?%\})m, Comment::Multiline
        rule %r/'.*$/, Comment::Single
      end

      state :bol do
        rule %r/\s+/, Text
        rule %r/<.*?>/, Name::Attribute
        rule(//) { :pop! }
      end

      state :root do
        mixin :whitespace
        rule %r(
            [#]If\b .*? \bThen
          | [#]ElseIf\b .*? \bThen
          | [#]End \s+ If
          | [#]Const
          | [#]ExternalSource .*? \n
          | [#]End \s+ ExternalSource
          | [#]Region .*? \n
          | [#]End \s+ Region
          | [#]ExternalChecksum
        )x, Comment::Preproc
        rule %r/[.]/, Punctuation, :dotted
        rule %r/[(){}!#,:]/, Punctuation
        rule %r/Option\s+(Strict|Explicit|Compare)\s+(On|Off|Binary|Text)/,
          Keyword::Declaration
        rule %r/End\b/, Keyword, :end
        rule %r/(Dim|Const)\b/, Keyword, :dim
        rule %r/(Function|Sub|Property)\b/, Keyword, :funcname
        rule %r/(Class|Structure|Enum)\b/, Keyword, :classname
        rule %r/(Module|Namespace|Imports)\b/, Keyword, :namespace

        rule upper_id do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.keywords_type.include? match
            token Keyword::Type
          elsif self.class.operator_words.include? match
            token Operator::Word
          elsif self.class.builtins.include? match
            token Name::Builtin
          else
            token Name
          end
        end

        rule(
          %r(&=|[*]=|/=|\\=|\^=|\+=|-=|<<=|>>=|<<|>>|:=|<=|>=|<>|[-&*/\\^+=<>.]),
          Operator
        )

        rule %r/"/, Str, :string
        rule %r/#{id}[%&@!#\$]?/, Name
        rule %r/#.*?#/, Literal::Date

        rule %r/(\d+\.\d*|\d*\.\d+)(f[+-]?\d+)?/i, Num::Float
        rule %r/\d+([SILDFR]|US|UI|UL)?/, Num::Integer
        rule %r/&H[0-9a-f]+([SILDFR]|US|UI|UL)?/, Num::Integer
        rule %r/&O[0-7]+([SILDFR]|US|UI|UL)?/, Num::Integer

        rule %r/_\n/, Keyword
      end

      state :dotted do
        mixin :whitespace
        rule id, Name, :pop!
      end

      state :string do
        rule %r/""/, Str::Escape
        rule %r/"C?/, Str, :pop!
        rule %r/[^"]+/, Str
      end

      state :dim do
        mixin :whitespace
        rule id, Name::Variable, :pop!
        rule(//) { pop! }
      end

      state :funcname do
        mixin :whitespace
        rule id, Name::Function, :pop!
      end

      state :classname do
        mixin :whitespace
        rule id, Name::Class, :pop!
      end

      state :namespace do
        mixin :whitespace
        rule %r/#{id}([.]#{id})*/, Name::Namespace, :pop!
      end

      state :end do
        mixin :whitespace
        rule %r/(Function|Sub|Property|Class|Structure|Enum|Module|Namespace)\b/,
          Keyword, :pop!
        rule(//) { pop! }
      end
    end
  end
end
