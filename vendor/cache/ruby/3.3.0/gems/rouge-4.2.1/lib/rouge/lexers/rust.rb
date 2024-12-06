# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Rust < RegexLexer
      title "Rust"
      desc 'The Rust programming language (rust-lang.org)'
      tag 'rust'
      aliases 'rs',
        # So that directives from https://github.com/budziq/rust-skeptic
        # do not prevent highlighting.
        'rust,no_run', 'rs,no_run',
        'rust,ignore', 'rs,ignore',
        'rust,should_panic', 'rs,should_panic'
      filenames '*.rs'
      mimetypes 'text/x-rust'

      def self.detect?(text)
        return true if text.shebang? 'rustc'
      end

      def self.keywords
        @keywords ||= %w(
          as async await break const continue crate dyn else enum extern false
          fn for if impl in let log loop match mod move mut pub ref return self
          Self static struct super trait true type unsafe use where while
          abstract become box do final macro
          override priv typeof unsized virtual
          yield try
          union
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          Add BitAnd BitOr BitXor bool c_char c_double c_float char
          c_int clock_t c_long c_longlong Copy c_schar c_short
          c_uchar c_uint c_ulong c_ulonglong c_ushort c_void dev_t DIR
          dirent Div Eq Err f32 f64 FILE float fpos_t
          i16 i32 i64 i8 isize Index ino_t int intptr_t mode_t Mul
          Neg None off_t Ok Option Ord Owned pid_t ptrdiff_t
          Send Shl Shr size_t Some ssize_t str Sub time_t
          u16 u32 u64 u8 usize uint uintptr_t
          Box Vec String Rc Arc
          u128 i128 Result Sync Pin Unpin Sized Drop drop Fn FnMut FnOnce
          Clone PartialEq PartialOrd AsMut AsRef From Into Default
          DoubleEndedIterator ExactSizeIterator Extend IntoIterator Iterator
          FromIterator ToOwned ToString TryFrom TryInto
        )
      end

      def macro_closed?
        @macro_delims.values.all?(&:zero?)
      end

      start {
        @macro_delims = { ']' => 0, ')' => 0, '}' => 0 }
        push :bol
      }

      delim_map = { '[' => ']', '(' => ')', '{' => '}' }

      id = /[\p{XID_Start}_]\p{XID_Continue}*/
      hex = /[0-9a-f]/i
      escapes = %r(
        \\ ([nrt'"\\0] | x#{hex}{2} | u\{(#{hex}_*){1,6}\})
      )x
      size = /8|16|32|64|128|size/

      # Although not officially part of Rust, the rustdoc tool allows code in
      # comments to begin with `#`. Code like this will be evaluated but not
      # included in the HTML output produced by rustdoc. So that code intended
      # for these comments can be higlighted with Rouge, the  Rust lexer needs
      # to check if the beginning of the line begins with a `# `.
      state :bol do
        mixin :whitespace
        rule %r/#\s[^\n]*/, Comment::Special
        rule(//) { pop! }
      end

      state :attribute do
        mixin :whitespace
        mixin :has_literals
        rule %r/[(,)=:]/, Name::Decorator
        rule %r/\]/, Name::Decorator, :pop!
        rule id, Name::Decorator
      end

      state :whitespace do
        rule %r/\s+/, Text
        mixin :comments
      end

      state :comments do
        # Only 3 slashes are doc comments, `////` and beyond become normal
        # comments again (for some reason), so match this before the
        # doc line comments rather than figure out a
        rule %r(////+[^\n]*), Comment::Single
        # doc line comments — either inner (`//!`), or outer (`///`).
        rule %r(//[/!][^\n]*), Comment::Doc
        # otherwise, `//` is just a plain line comme
        rule %r(//[^\n]*), Comment::Single
        # /**/ and /***/ are self-closing block comments, not doc. Because this
        # is self-closing, it doesn't enter the states for nested comments
        rule %r(/\*\*\*?/), Comment::Multiline
        # 3+ stars and it's a normal non-doc block comment.
        rule %r(/\*\*\*+), Comment::Multiline, :nested_plain_block
        # `/*!` and `/**` begin doc comments. These nest and can have internal
        # block/doc comments, but they're still part of the documentation
        # inside.
        rule %r(/[*][*!]), Comment::Doc, :nested_doc_block
        # any other /* is a plain multiline comment
        rule %r(/[*]), Comment::Multiline, :nested_plain_block
      end

      # Multiline/block comments fully nest. This is true for ones that are
      # marked as documentation too. The behavior here is:
      #
      # - Anything inside a block doc comment is still included in the
      #   documentation, even if it's a nested non-doc block comment. For
      #   example: `/** /* still docs */ */`
      # - Anything inside of a block non-doc comment is still just a normal
      #   comment, even if it's a nested block documentation comment. For
      #   example: `/* /** not docs */ */`
      #
      # This basically means: if (on the outermost level) the comment starts as
      # one kind of block comment (either doc/non-doc), then everything inside
      # of it, including nested block comments of the opposite type, needs to
      # stay that type.
      #
      # Also note that single line comments do nothing anywhere inside of block
      # comments, thankfully.
      #
      # We just define this as two states, because this seems easier than
      # tracking it with instance vars.
      [
        [:nested_plain_block, Comment::Multiline],
        [:nested_doc_block, Comment::Doc]
      ].each do |state_name, comment_token|
        state state_name do
          rule %r(\*/), comment_token, :pop!
          rule %r(/\*), comment_token, state_name
          # We only want to eat at most one `[*/]` at a time,
          # but we can skip past non-`[*/]` in bulk.
          rule %r([^*/]+|[*/]), comment_token
        end
      end

      state :root do
        rule %r/\n/, Text, :bol
        mixin :whitespace
        rule %r/#!?\[/, Name::Decorator, :attribute
        rule %r/\b(?:#{Rust.keywords.join('|')})\b/, Keyword
        mixin :has_literals

        rule %r([=-]>), Keyword
        rule %r(<->), Keyword
        rule %r/[()\[\]{}|,:;]/, Punctuation
        rule %r/[*\/!@~&+%^<>=\?-]|\.{2,3}/, Operator

        rule %r/([.]\s*)?#{id}(?=\s*[(])/m, Name::Function
        rule %r/[.]\s*await\b/, Keyword
        rule %r/[.]\s*#{id}/, Name::Property
        rule %r/[.]\s*\d+/, Name::Attribute
        rule %r/(#{id})(::)/m do
          groups Name::Namespace, Punctuation
        end

        # macros
        rule %r/\bmacro_rules!/, Name::Decorator, :macro_rules
        rule %r/#{id}!/, Name::Decorator, :macro

        rule %r/'static\b/, Keyword
        rule %r/'#{id}/, Name::Variable
        rule %r/#{id}/ do |m|
          name = m[0]
          if self.class.builtins.include? name
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :macro do
        mixin :has_literals

        rule %r/[\[{(]/ do |m|
          @macro_delims[delim_map[m[0]]] += 1
          puts "    macro_delims: #{@macro_delims.inspect}" if @debug
          token Punctuation
        end

        rule %r/[\]})]/ do |m|
          @macro_delims[m[0]] -= 1
          puts "    macro_delims: #{@macro_delims.inspect}" if @debug
          pop! if macro_closed?
          token Punctuation
        end

        # same as the rule in root, but don't push another macro state
        rule %r/#{id}!/, Name::Decorator
        mixin :root

        # No syntax errors in macros
        rule %r/./, Text
      end

      state :macro_rules do
        rule %r/[$]#{id}(:#{id})?/, Name::Variable
        rule %r/[$]/, Name::Variable

        mixin :macro
      end

      state :has_literals do
        # constants
        rule %r/\b(?:true|false)\b/, Keyword::Constant

        # characters/bytes
        rule %r(
          b?' (?: #{escapes} | [^\\] ) '
        )x, Str::Char

        rule %r/b?"/, Str, :string
        rule %r/b?r(#*)".*?"\1/m, Str

        # numbers
        dot = /[.][0-9][0-9_]*/
        exp = /[eE][-+]?[0-9_]+/
        flt = /f32|f64/

        rule %r(
          [0-9][0-9_]*
          (#{dot}  #{exp}? #{flt}?
          |#{dot}? #{exp}  #{flt}?
          |#{dot}? #{exp}? #{flt}
          |[.](?![._\p{XID_Start}])
          )
        )x, Num::Float

        rule %r(
          ( 0b[10_]+
          | 0x[0-9a-fA-F_]+
          | 0o[0-7_]+
          | [0-9][0-9_]*
          ) (u#{size}?|i#{size})?
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
