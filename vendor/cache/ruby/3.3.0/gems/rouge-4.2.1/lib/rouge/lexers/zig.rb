# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Zig < RegexLexer
      tag 'zig'
      aliases 'zir'
      filenames '*.zig'
      mimetypes 'text/x-zig'

      title 'Zig'
      desc 'The Zig programming language (ziglang.org)'

      def self.keywords
        @keywords ||= %w(
          align linksection threadlocal struct enum union error break return
          anyframe fn c_longlong c_ulonglong c_longdouble c_void comptime_float
          c_short c_ushort c_int c_uint c_long c_ulong continue asm defer
          errdefer const var extern packed export pub if else switch and or
          orelse while for bool unreachable try catch async suspend nosuspend
          await resume undefined usingnamespace test void noreturn type
          anyerror usize noalias inline noinline comptime callconv volatile
          allowzero
        )
      end

      def self.builtins
        @builtins ||= %w(
          @addWithOverflow @as @atomicLoad @atomicStore @bitCast @breakpoint
          @alignCast @alignOf @cDefine @cImport @cInclude @bitOffsetOf
          @atomicRmw @bytesToSlice @byteOffsetOf @OpaqueType @panic @ptrCast
          @bitReverse @Vector @sin @cUndef @canImplicitCast @clz @cmpxchgWeak
          @cmpxchgStrong @compileError @compileLog @ctz @popCount @divExact
          @divFloor @cos @divTrunc @embedFile @export @tagName @TagType
          @errorName @call @errorReturnTrace @fence @fieldParentPtr @field
          @unionInit @errorToInt @intToEnum @enumToInt @setAlignStack @frame
          @Frame @exp @exp2 @log @log2 @log10 @fabs @floor @ceil @trunc @round
          @floatCast @intToFloat @floatToInt @boolToInt @errSetCast @intToError
          @frameAddress @import @newStackCall @asyncCall @intToPtr @intCast
          @frameSize @memcpy @memset @mod @mulWithOverflow @splat @ptrToInt
          @rem @returnAddress @setCold @Type @shuffle @setGlobalLinkage
          @setGlobalSection @shlExact @This @hasDecl @hasField
          @setRuntimeSafety @setEvalBranchQuota @setFloatMode @shlWithOverflow
          @shrExact @sizeOf @bitSizeOf @sqrt @byteSwap @subWithOverflow
          @sliceToBytes comptime_int @truncate @typeInfo @typeName @TypeOf
        )
      end

      id = /[a-z_]\w*/i
      escapes = /\\ ([nrt'"\\0] | x\h{2} | u\h{4} | U\h{8})/x

      state :bol do
        mixin :whitespace
        rule %r/#\s[^\n]*/, Comment::Special
        rule(//) { pop! }
      end

      state :attribute do
        mixin :whitespace
        mixin :literals
        rule %r/[(,)=:]/, Name::Decorator
        rule %r/\]/, Name::Decorator, :pop!
        rule id, Name::Decorator
      end

      state :whitespace do
        rule %r/\s+/, Text
        rule %r(//[^\n]*), Comment
      end

      state :root do
        rule %r/\n/, Text, :bol

        mixin :whitespace

        rule %r/\b(?:(i|u)[0-9]+)\b/, Keyword::Type
        rule %r/\b(?:f(16|32|64|128))\b/, Keyword::Type
        rule %r/\b(?:(isize|usize))\b/, Keyword::Type

        mixin :literals

        rule %r/'#{id}/, Name::Variable
        rule %r/([.]?)(\s*)(@?#{id})(\s*)([(]?)/ do |m|
          name = m[3]
          t = if self.class.keywords.include? name
                Keyword
              elsif self.class.builtins.include? name
                Name::Builtin
              elsif !m[1].empty? && !m[5].empty?
                Name::Function
              elsif !m[1].empty?
                Name::Property
              else
                Name
              end

          groups Punctuation, Text, t, Text, Punctuation
        end

        rule %r/[()\[\]{}|,:;]/, Punctuation
        rule %r/[*\/!@~&+%^<>=\?-]|\.{1,3}/, Operator
      end

      state :literals do
        rule %r/\b(?:true|false|null)\b/, Keyword::Constant
        rule %r(
        ' (?: #{escapes} | [^\\] ) '
        )x, Str::Char

        rule %r/"/, Str, :string
        rule %r/r(#*)".*?"\1/m, Str

        dot = /[.][0-9_]+/
        exp = /e[-+]?[0-9_]+/

        rule %r(
          [0-9]+
          (#{dot}  #{exp}?
          |#{dot}? #{exp}
          )
        )x, Num::Float

        rule %r(
        ( 0b[10_]+
         | 0x[0-9a-fA-F_]+
         | [0-9_]+
        )
        )x, Num::Integer
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule escapes, Str::Escape
        rule %r/[^"\\]+/m, Str
      end
    end
  end
end
