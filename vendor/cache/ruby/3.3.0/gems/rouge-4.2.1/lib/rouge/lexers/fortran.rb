# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# vim: set ts=2 sw=2 et:

# TODO: Implement format list support.

module Rouge
  module Lexers
    class Fortran < RegexLexer
      title "Fortran"
      desc "Fortran 2008 (free-form)"

      tag 'fortran'
      filenames '*.f', '*.f90', '*.f95', '*.f03', '*.f08',
                '*.F', '*.F90', '*.F95', '*.F03', '*.F08'
      mimetypes 'text/x-fortran'

      name = /[A-Z][_A-Z0-9]*/i
      kind_param = /(\d+|#{name})/
      exponent = /[ED][+-]?\d+/i

      def self.keywords
        # Special rules for two-word keywords are defined further down.
        # Note: Fortran allows to omit whitespace between certain keywords.
        @keywords ||= Set.new %w(
          abstract allocatable allocate assign assignment associate asynchronous
          backspace bind block blockdata call case class close codimension
          common concurrent contains contiguous continue critical cycle data
          deallocate deferred dimension do elemental else elseif elsewhere end
          endassociate endblock endblockdata enddo endenum endfile endforall
          endfunction endif endinterface endmodule endprogram endselect
          endsubmodule endsubroutine endtype endwhere endwhile entry enum
          enumerator equivalence exit extends external final flush forall format
          function generic goto if implicit import in include inout inquire
          intent interface intrinsic is lock module namelist non_overridable
          none nopass nullify only open operator optional out parameter pass
          pause pointer print private procedure program protected public pure
          read recursive result return rewind save select selectcase sequence
          stop submodule subroutine target then type unlock use value volatile
          wait where while write
        )
      end

      def self.types
        # A special rule for the two-word version "double precision" is
        # defined further down.
        @types ||= Set.new %w(
          character complex doubleprecision integer logical real
        )
      end

      def self.intrinsics
        @intrinsics ||= Set.new %w(
          abs achar acos acosh adjustl adjustr aimag aint all allocated anint
          any asin asinh associated atan atan2 atanh atomic_define atomic_ref
          bessel_j0 bessel_j1 bessel_jn bessel_y0 bessel_y1 bessel_yn bge bgt
          bit_size ble blt btest c_associated c_f_pointer c_f_procpointer
          c_funloc c_loc c_sizeof ceiling char cmplx command_argument_count
          compiler_options compiler_version conjg cos cosh count cpu_time cshift
          date_and_time dble digits dim dot_product dprod dshiftl dshiftr
          eoshift epsilon erf erfc_scaled erfc execute_command_line exp exponent
          extends_type_of findloc floor fraction gamma get_command_argument
          get_command get_environment_variable huge hypot iachar iall iand iany
          ibclr ibits ibset ichar ieee_class ieee_copy_sign ieee_get_flag
          ieee_get_halting_mode ieee_get_rounding_mode ieee_get_status
          ieee_get_underflow_mode ieee_is_finite ieee_is_nan ieee_is_normal
          ieee_logb ieee_next_after ieee_rem ieee_rint ieee_scalb
          ieee_selected_real_kind ieee_set_flag ieee_set_halting_mode
          ieee_set_rounding_mode ieee_set_status ieee_set_underflow_mode
          ieee_support_datatype ieee_support_denormal ieee_support_divide
          ieee_support_flag ieee_support_halting ieee_support_inf
          ieee_support_io ieee_support_nan ieee_support_rounding
          ieee_support_sqrt ieee_support_standard ieee_support_underflow_control
          ieee_unordered ieee_value ieor image_index index int ior iparity
          is_contiguous is_iostat_end is_iostat_eor ishft ishftc kind lbound
          lcobound leadz len_trim len lge lgt lle llt log_gamma log log10
          logical maskl maskr matmul max maxexponent maxloc maxval merge_bits
          merge min minexponent minloc minval mod modulo move_alloc mvbits
          nearest new_line nint norm2 not null num_images pack parity popcnt
          poppar present product radix random_number random_seed range real
          repeat reshape rrspacing same_type_as scale scan selected_char_kind
          selected_int_kind selected_real_kind set_exponent shape shifta shiftl
          shiftr sign sin sinh size spacing spread sqrt storage_size sum
          system_clock tan tanh this_image tiny trailz transfer transpose trim
          ubound ucobound unpack verify
        )
      end

      state :root do
        rule %r/[\s]+/, Text::Whitespace
        rule %r/!.*$/, Comment::Single
        rule %r/^#.*$/, Comment::Preproc

        rule %r/::|[()\/;,:&\[\]]/, Punctuation

        # TODO: This does not take into account line continuation.
        rule %r/^(\s*)([0-9]+)\b/m do |m|
          token Text::Whitespace, m[1]
          token Name::Label, m[2]
        end

        # Format statements are quite a strange beast.
        # Better process them in their own state.
        rule %r/\b(FORMAT)(\s*)(\()/mi do |m|
          token Keyword, m[1]
          token Text::Whitespace, m[2]
          token Punctuation, m[3]
          push :format_spec
        end

        rule %r(
          [+-]? # sign
          (
            (\d+[.]\d*|[.]\d+)(#{exponent})?
            | \d+#{exponent} # exponent is mandatory
          )
          (_#{kind_param})? # kind parameter
        )xi, Num::Float

        rule %r/[+-]?\d+(_#{kind_param})?/i, Num::Integer
        rule %r/B'[01]+'|B"[01]+"/i, Num::Bin
        rule %r/O'[0-7]+'|O"[0-7]+"/i, Num::Oct
        rule %r/Z'[0-9A-F]+'|Z"[0-9A-F]+"/i, Num::Hex
        rule %r/(#{kind_param}_)?'/, Str::Single, :string_single
        rule %r/(#{kind_param}_)?"/, Str::Double, :string_double
        rule %r/[.](TRUE|FALSE)[.](_#{kind_param})?/i, Keyword::Constant

        rule %r{\*\*|//|==|/=|<=|>=|=>|[-+*/<>=%]}, Operator
        rule %r/\.(?:EQ|NE|LT|LE|GT|GE|NOT|AND|OR|EQV|NEQV|[A-Z]+)\./i, Operator::Word

        # Special rules for two-word keywords and types.
        # Note: "doubleprecision" is covered by the normal keyword rule.
        rule %r/double\s+precision\b/i, Keyword::Type
        rule %r/go\s+to\b/i, Keyword
        rule %r/sync\s+(all|images|memory)\b/i, Keyword
        rule %r/error\s+stop\b/i, Keyword

        rule %r/#{name}/m do |m|
          match = m[0].downcase
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.types.include? match
            token Keyword::Type
          elsif self.class.intrinsics.include? match
            token Name::Builtin
          else
            token Name
          end
        end

      end

      state :string_single do
        rule %r/[^']+/, Str::Single
        rule %r/''/, Str::Escape
        rule %r/'/, Str::Single, :pop!
      end

      state :string_double do
        rule %r/[^"]+/, Str::Double
        rule %r/""/, Str::Escape
        rule %r/"/, Str::Double, :pop!
      end

      state :format_spec do
        rule %r/'/, Str::Single, :string_single
        rule %r/"/, Str::Double, :string_double
        rule %r/\(/, Punctuation, :format_spec
        rule %r/\)/, Punctuation, :pop!
        rule %r/,/, Punctuation
        rule %r/[\s]+/, Text::Whitespace
        # Edit descriptors could be seen as a kind of "format literal".
        rule %r/[^\s'"(),]+/, Literal
      end
    end
  end
end
