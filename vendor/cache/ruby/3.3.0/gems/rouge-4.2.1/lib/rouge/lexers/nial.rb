# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Nial < RegexLexer
      title 'Nial'
      desc 'The Nial programming language (nial-array-language.org)'
      tag 'nial'
      filenames '*.ndf', '*.nlg'
      
      def self.keywords
        @keywords ||= Set.new ["is", "gets", "op", "tr", ";",
                     "if", "then", "elseif", "else",
                     "endif", "case", "from", "endcase",
                     "begin", "end", "for", "with",
                     "endfor", "while", "do", "endwhile",
                     "repeat", "until", "endrepeat"]
      end

      def self.operators
        @operators||= Set.new [".",  "!", "#", "+", "*", "-", "<<",
                 "/", "<", ">>", "<=", ">", "=", ">=", "@", "|", "~="]
      end

      def self.punctuations
        @punctuations ||= Set.new [ "{", "}", "[", "]", ",", "(", ")", ":=", ":", ";"]
      end

      def self.transformers
        @transformers ||= Set.new ["accumulate", "across",
        "bycols", "bykey",  "byrows",
        "converse",  "down",
        "eachboth", "eachall", "each",
        "eachleft", "eachright",
        "filter", "fold", "fork",
        "grade",  "inner", "iterate",
        "leaf",  "no_tr", "outer",
        "partition", "rank", "recur",
        "reduce", "reducecols", "reducerows",
        "sort", "team", "timeit", "twig"]
      end
      
      def self.funcs
        @funcs ||= Set.new ["operation", "expression", "and", "abs",
                  "allbools", "allints", "allchars", "allin",
                  "allreals", "allnumeric", "append",
                  "arcsin", "arccos", "appendfile", "apply",
                  "arctan", "atomic", "assign", "atversion",
                  "axes", "cart", "break", "blend", "breaklist",
                  "breakin", "bye", "callstack", "choose", "char",
                  "ceiling", "catenate", "charrep", "check_socket",
                  "cos", "content", "close", "clearws",
                  "clearprofile", "cols", "continue", "copyright",
                  "cosh", "cull", "count", "diverse", "deepplace",
                  "cutall", "cut", "display", "deparse",
                  "deepupdate", "descan", "depth", "diagram",
                  "div", "divide", "drop", "dropright", "edit",
                  "empty", "expression", "exit", "except", "erase",
                  "equal", "eval", "eraserecord", "execute", "exp",
                  "external", "exprs", "findall", "find", 
                  "fault", "falsehood", "filestatus", "filelength",
                  "filepath", "filetally", "floor", "first",
                  "flip", "fuse", "fromraw", "front",
                  "gage", "getfile", "getdef", "getcommandline",
                  "getenv", "getname", "hitch", "grid", "getsyms",
                  "gradeup", "gt", "gte", "host", "in", "inverse",
                  "innerproduct", "inv", "ip", "ln", "link", "isboolean",
                  "isinteger", "ischar", "isfault", "isreal", "isphrase",
                  "isstring", "istruthvalue", "last", "laminate",
                  "like", "libpath", "library", "list", "load",
                  "loaddefs", "nonlocal", "max", "match", "log",
                  "lt", "lower", "lte", "mate", "min", "maxlength",
                  "mod", "mix", "minus", "nialroot", "mold", "not",
                  "numeric", "no_op", "no_expr", "notin",
                  "operation", "open", "or", "opposite", "opp",
                  "operators", "plus", "pick", "pack", "pass", "pair", "parse",
                  "paste", "phrase", "place", "picture", "placeall",
                  "power", "positions", "post", "quotient", "putfile",
                  "profile", "prod", "product", "profiletree",
                  "profiletable", "quiet_fault", "raise", "reach",
                  "random", "reciprocal", "read", "readfile",
                  "readchar", "readarray", "readfield",
                  "readscreen", "readrecord", "recip", "reshape",
                  "seek", "second", "rest", "reverse", "restart",
                  "return_status", "scan", "save", "rows", "rotate",
                  "seed", "see", "sublist", "sin", "simple", "shape",
                  "setformat", "setdeftrace", "set", "seeusercalls",
                  "seeprimcalls", "separator", "setwidth", "settrigger",
                  "setmessages", "setlogname", "setinterrupts",
                  "setprompt", "setprofile", "sinh", "single",
                  "sqrt", "solitary", "sketch", "sleep",
                  "socket_listen", "socket_accept", "socket_close",
                  "socket_bind", "socket_connect", "socket_getline",
                  "socket_receive", "socket_peek", "socket_read",
                  "socket_send", "socket_write", "solve", "split",
                  "sortup", "string", "status", "take", "symbols",
                  "sum", "system", "tan", "tally", "takeright",
                  "tanh", "tell", "tr", "times", "third", "time",
                  "toupper", "tolower", "timestamp", "tonumber",
                  "toraw", "toplevel", "transformer", "type",
                  "transpose", "trs", "truth", "unequal",
                  "variable", "valence", "up", "updateall",
                  "update", "vacate", "value", "version", "vars",
                  "void", "watch", "watchlist", "write", "writechars",
                  "writearray", "writefile", "writefield",
                  "writescreen", "writerecord"]
      end

      def self.consts
        @consts ||= Set.new %w(false null pi true)
      end

      state :root do
        rule %r/'/, Str::Single, :str
        rule %r/\b[lo]+\b/, Num::Bin
        rule %r/-?\d+((\.\d*)?[eE][+-]?\d|\.)\d*/, Num::Float
        rule %r/\-?\d+/, Num::Integer
        rule %r/`./, Str::Char
        rule %r/"[^\s()\[\]{}#,;]*/, Str::Symbol
        rule %r/\?[^\s()\[\]{}#,;]*/, Generic::Error
        rule %r/%[^;]+;/, Comment::Multiline
        rule %r/^#(.+\n)+\n/, Comment::Multiline
        rule %r/:=|[\{\}\[\]\(\),:;]/ do |m|
          if self.class.punctuations.include?(m[0])
            token Punctuation
          else
            token Text
          end
        end
        # [".",  "!", "#", "+", "*", "-", "<<",
        #   "/", "<", ">>", "<=", ">", "=", ">=", "@", "|", "~="]
        rule %r'>>|>=|<=|~=|[\.!#+*\-=></|@]' do |m|
          if self.class.operators.include?(m[0])
            token Operator
          else
            token Text
          end
        end
        
        rule %r/\b[_A-Za-z]\w*\b/ do |m|
          lower = m[0].downcase
          if self.class.keywords.include?(lower)
            token Keyword
          elsif self.class.funcs.include?(lower)
            token Keyword::Pseudo
          elsif self.class.transformers.include?(lower)
            token Name::Builtin
          elsif self.class.consts.include?(lower)
            token Keyword::Constant
          else
            token Name::Variable
          end
        end

        rule %r/\s+/, Text
      end
      
      state :str do
        rule %r/''/, Str::Escape
        rule %r/[^']+/, Str::Single
        rule %r/'|$/, Str::Single, :pop!
      end
    end
  end
end
