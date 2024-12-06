# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Verilog < RegexLexer
      title "Verilog and System Verilog"
      desc "The System Verilog hardware description language"
      tag 'verilog'
      filenames '*.v', '*.sv', '*.svh'
      mimetypes 'text/x-verilog', 'text/x-systemverilog'

      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      def self.keywords
        @keywords ||= Set.new %w(
          alias always always_comb always_ff always_latch assert assert_strobe
          assign assume automatic attribute before begin bind bins binsof break
          case casex casez clocking config constraint context continue cover
          covergroup coverpoint cross deassign defparam default design dist do
          else end endattribute endcase endclass endclocking endconfig
          endfunction endgenerate endgroup endinterface endmodule endpackage
          endprimitive endprogram endproperty endspecify endsequence endtable
          endtask expect export extends extern final first_match for force
          foreach fork forkjoin forever function generate genvar if iff ifnone
          ignore_bins illegal_bins import incdir include initial inside instance
          interface intersect join join_any join_none liblist library local
          localparam  matches module modport new noshowcancelled null package
          parameter primitive priority program property protected
          pulsestyle_onevent  pulsestyle_ondetect pure rand randc randcase
          randsequence release return sequence showcancelled solve specify super
          table task this throughout timeprecision timeunit type typedef unique
          use wait wait_order while wildcard with within
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          and bit buf bufif0 bufif1 byte cell chandle class cmos const disable
          edge enum event highz0 highz1 initial inout input int integer join
          logic longint macromodule medium nand negedge nmos nor not
          notif0 notif1 or output packed parameter pmos posedge pull0 pull1
          pulldown pullup rcmos real realtime ref reg repeat rnmos rpmos rtran
          rtranif0 rtranif1 scalared shortint shortreal signed  specparam
          static string strength strong0 strong1 struct supply0 supply1 tagged
          time tran tranif0 tranif1 tri tri0 tri1 triand trior trireg union
          unsigned uwire var vectored virtual void wait wand weak[01] wire wor
          xnor xor
        )
      end

      def self.keywords_system_task
        @keyword_system_task ||= Set.new %w(
          acos acosh asin asinh assertfailoff assertfailon  assertkill
          assertnonvacuouson assertoff asserton assertpassoff assertpasson
          assertvacuousoff atan atan2 atanh bits bitstoreal  bitstoshortreal
          cast ceil changed changed_gclk changing_gclk clog2 cos cosh countones
          coverage_control coverage_get coverage_get_max coverage_merge
          coverage_save dimensions display displayb displayh displayo
          dist_chi_square dist_erlang dist_exponential dist_normal dist_poisson
          dist_t dist_uniform dumpall dumpfile dumpflush dumplimit dumpoff
          dumpon dumpports dumpportsall dumpportsflush dumpportslimit
          dumpportsoff dumpportson dumpvars error exit exp falling_gclk fclose
          fdisplay fdisplayb fdisplayh fdisplayo fell fell_gclk feof ferror
          fflush fgetc fgets finish floor fmonitor fmonitorb fmonitorh fmonitoro
          fopen fread fscanf fseek fstrobe fstrobeb fstrobeh fstrobeo ftell
          future_gclk fwrite fwriteb fwriteh fwriteo get_coverage high hypot
          increment info isunbounded isunknown itor left ln load_coverage_db
          log10 low monitor monitorb monitorh monitoro monitoroff monitoron
          onehot onehot0 past past_gclk pow printtimescale q_add q_exam q_full
          q_initialize q_remove random readmemb readmemh realtime realtobits
          rewind right rising_gclk rose rose_gclk rtoi sampled
          set_coverage_db_name sformat sformatf shortrealtobits signed sin sinh
          size sqrt sscanf stable stable_gclk steady_gclk stime stop strobe
          strobeb strobeh strobeo swrite swriteb swriteh swriteo system tan tanh
          time timeformat typename ungetc unpacked_dimensions unsigned warning
          write writeb writeh writememb writememh writeo
        )
      end

      state :expr_bol do
        mixin :inline_whitespace
        rule %r/`define/, Comment::Preproc, :macro

        rule(//) { pop! }
      end

      # :expr_bol is the same as :bol but without labels, since
      # labels can only appear at the beginning of a statement.
      state :bol do
        rule %r/#{id}:(?!:)/, Name::Label
        mixin :expr_bol
      end

      state :inline_whitespace do
        rule %r/[ \t\r]+/, Text
        rule %r/\\\n/, Text # line continuation
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :whitespace do
        rule %r/\n+/m, Text, :bol
        rule %r(//(\\.|.)*?$), Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :expr_whitespace do
        rule %r/\n+/m, Text, :expr_bol
        mixin :whitespace
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\\n/, Str
        rule %r/\\/, Str # stray backslash
      end

      state :statement do
        mixin :whitespace
        rule %r/L?"/, Str, :string
        rule %r/([0-9_]+\.[0-9_]*|[0-9_]*\.[0-9_]+)(e[+-]?[0-9_]+)?/i, Num::Float
        rule %r/[0-9_]+e[+-]?[0-9_]+/i, Num::Float
        rule %r/[0-9]*'h[0-9a-fA-F_?]+/, Num::Hex
        rule %r/[0-9]*'b?[01xz_?]+/, Num::Bin
        rule %r/[0-9]*'d[0-9_?]+/, Num::Integer
        rule %r/[0-9_]+[lu]*/i, Num::Integer
        rule %r([-~!%^&*+=\|?:<>/@{}]), Operator
        rule %r/[()\[\],.$\#;]/, Punctuation
        rule %r/`(\w+)/, Comment::Preproc

        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.keywords_system_task.include? name
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :root do
        mixin :expr_whitespace
        rule(//) { push :statement }
      end

      state :macro do
        rule %r/\n/, Comment::Preproc, :pop!
        mixin :inline_whitespace
        rule %r/;/, Punctuation
        rule %r/\=/, Operator
        rule %r/(\w+)/, Text
      end

    end
  end
end
