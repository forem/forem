# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Erlang < RegexLexer
      title "Erlang"
      desc "The Erlang programming language (erlang.org)"
      tag 'erlang'
      aliases 'erl'
      filenames '*.erl', '*.hrl'

      mimetypes 'text/x-erlang', 'application/x-erlang'

      keywords = %w(
        after begin case catch cond end fun if
        let of query receive try when
      )

      builtins = %w(
        abs append_element apply atom_to_list binary_to_list
        bitstring_to_list binary_to_term bit_size bump_reductions
        byte_size cancel_timer check_process_code delete_module
        demonitor disconnect_node display element erase exit
        float float_to_list fun_info fun_to_list
        function_exported garbage_collect get get_keys
        group_leader hash hd integer_to_list iolist_to_binary
        iolist_size is_atom is_binary is_bitstring is_boolean
        is_builtin is_float is_function is_integer is_list
        is_number is_pid is_port is_process_alive is_record
        is_reference is_tuple length link list_to_atom
        list_to_binary list_to_bitstring list_to_existing_atom
        list_to_float list_to_integer list_to_pid list_to_tuple
        load_module localtime_to_universaltime make_tuple md5
        md5_final md5_update memory module_loaded monitor
        monitor_node node nodes open_port phash phash2
        pid_to_list port_close port_command port_connect
        port_control port_call port_info port_to_list
        process_display process_flag process_info purge_module
        put read_timer ref_to_list register resume_process
        round send send_after send_nosuspend set_cookie
        setelement size spawn spawn_link spawn_monitor
        spawn_opt split_binary start_timer statistics
        suspend_process system_flag system_info system_monitor
        system_profile term_to_binary tl trace trace_delivered
        trace_info trace_pattern trunc tuple_size tuple_to_list
        universaltime_to_localtime unlink unregister whereis
      )

      operators = %r{(\+\+?|--?|\*|/|<|>|/=|=:=|=/=|=<|>=|==?|<-|!|\?)}
      word_operators = %w(
        and andalso band bnot bor bsl bsr bxor
        div not or orelse rem xor
      )

      atom_re = %r{(?:[a-z][a-zA-Z0-9_]*|'[^\n']*[^\\]')}

      variable_re = %r{(?:[A-Z_][a-zA-Z0-9_]*)}

      escape_re = %r{(?:\\(?:[bdefnrstv\'"\\/]|[0-7][0-7]?[0-7]?|\^[a-zA-Z]))}

      macro_re = %r{(?:#{variable_re}|#{atom_re})}

      base_re = %r{(?:[2-9]|[12][0-9]|3[0-6])}

      state :root do
        rule(/\s+/, Text)
        rule(/%.*\n/, Comment)
        rule(%r{(#{keywords.join('|')})\b}, Keyword)
        rule(%r{(#{builtins.join('|')})\b}, Name::Builtin)
        rule(%r{(#{word_operators.join('|')})\b}, Operator::Word)
        rule(/^-/, Punctuation, :directive)
        rule(operators, Operator)
        rule(/"/, Str, :string)
        rule(/<</, Name::Label)
        rule(/>>/, Name::Label)
        rule %r{(#{atom_re})(:)} do
          groups Name::Namespace, Punctuation
        end
        rule %r{(?:^|(?<=:))(#{atom_re})(\s*)(\()} do
          groups Name::Function, Text, Punctuation
        end
        rule(%r{[+-]?#{base_re}#[0-9a-zA-Z]+}, Num::Integer)
        rule(/[+-]?\d+/, Num::Integer)
        rule(/[+-]?\d+.\d+/, Num::Float)
        rule(%r{[\]\[:_@\".{}()|;,]}, Punctuation)
        rule(variable_re, Name::Variable)
        rule(atom_re, Name)
        rule(%r{\?#{macro_re}}, Name::Constant)
        rule(%r{\$(?:#{escape_re}|\\[ %]|[^\\])}, Str::Char)
        rule(%r{##{atom_re}(:?\.#{atom_re})?}, Name::Label)
      end

      state :string do
        rule(escape_re, Str::Escape)
        rule(/"/, Str, :pop!)
        rule(%r{~[0-9.*]*[~#+bBcdefginpPswWxX]}, Str::Interpol)
        rule(%r{[^"\\~]+}, Str)
        rule(/~/, Str)
      end

      state :directive do
        rule %r{(define)(\s*)(\()(#{macro_re})} do
          groups Name::Entity, Text, Punctuation, Name::Constant
          pop!
        end
        rule %r{(record)(\s*)(\()(#{macro_re})} do
          groups Name::Entity, Text, Punctuation, Name::Label
          pop!
        end
        rule(atom_re, Name::Entity, :pop!)
      end
    end
  end
end
