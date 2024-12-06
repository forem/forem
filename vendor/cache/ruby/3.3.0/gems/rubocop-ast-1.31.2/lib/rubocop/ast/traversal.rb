# frozen_string_literal: true

module RuboCop
  module AST
    # Provides methods for traversing an AST.
    # Does not transform an AST; for that, use Parser::AST::Processor.
    # Override methods to perform custom processing. Remember to call `super`
    # if you want to recursively process descendant nodes.
    module Traversal
      # Only for debugging.
      # @api private
      class DebugError < RuntimeError
      end

      TYPE_TO_METHOD = Hash.new { |h, type| h[type] = :"on_#{type}" }

      def walk(node)
        return if node.nil?

        send(TYPE_TO_METHOD[node.type], node)
        nil
      end

      # @api private
      module CallbackCompiler
        SEND = 'send(TYPE_TO_METHOD[child.type], child)'
        assign_code = 'child = node.children[%<index>i]'
        code = "#{assign_code}\n#{SEND}"
        TEMPLATE = {
          skip: '',
          always: code,
          nil?: "#{code} if child"
        }.freeze

        def def_callback(type, *signature,
                         arity: signature.size..signature.size,
                         arity_check: ENV.fetch('RUBOCOP_DEBUG', nil) && self.arity_check(arity),
                         body: self.body(signature, arity_check))
          type, *aliases = type
          lineno = caller_locations(1, 1).first.lineno
          module_eval(<<~RUBY, __FILE__, lineno) # rubocop:disable Style/EvalWithLocation
            def on_#{type}(node)        # def on_send(node)
              #{body}                   #   # body ...
              nil                       #   nil
            end                         # end
          RUBY
          aliases.each do |m|
            alias_method :"on_#{m}", :"on_#{type}"
          end
        end

        def body(signature, prelude)
          signature
            .map.with_index do |arg, i|
              TEMPLATE[arg].gsub('%<index>i', i.to_s)
            end
            .unshift(prelude)
            .join("\n")
        end

        def arity_check(range)
          <<~RUBY
            n = node.children.size
            raise DebugError, [
              'Expected #{range} children, got',
              n, 'for', node.inspect
            ].join(' ') unless (#{range}).cover?(node.children.size)
          RUBY
        end
      end
      private_constant :CallbackCompiler
      extend CallbackCompiler
      send_code = CallbackCompiler::SEND

      ### arity == 0
      no_children = %i[true false nil self cbase zsuper redo retry
                       forward_args forwarded_args match_nil_pattern
                       forward_arg forwarded_restarg forwarded_kwrestarg
                       lambda empty_else kwnilarg
                       __FILE__ __LINE__ __ENCODING__]

      ### arity == 0..1
      opt_symbol_child = %i[restarg kwrestarg]
      opt_node_child = %i[splat kwsplat match_rest]

      ### arity == 1
      literal_child = %i[int float complex
                         rational str sym lvar
                         ivar cvar gvar nth_ref back_ref
                         arg blockarg shadowarg
                         kwarg match_var]

      many_symbol_children = %i[regopt]

      node_child = %i[not match_current_line defined?
                      arg_expr pin if_guard unless_guard
                      match_with_trailing_comma]
      node_or_nil_child = %i[block_pass preexe postexe]

      NO_CHILD_NODES = (no_children + opt_symbol_child + literal_child).to_set.freeze
      private_constant :NO_CHILD_NODES # Used by Commissioner

      ### arity > 1
      symbol_then_opt_node = %i[lvasgn ivasgn cvasgn gvasgn]
      symbol_then_node_or_nil = %i[optarg kwoptarg]
      node_then_opt_node = %i[while until module sclass]

      ### variable arity
      many_node_children = %i[dstr dsym xstr regexp array hash pair
                              mlhs masgn or_asgn and_asgn rasgn mrasgn
                              undef alias args super yield or and
                              while_post until_post iflipflop eflipflop
                              match_with_lvasgn begin kwbegin return
                              in_match match_alt break next
                              match_as array_pattern array_pattern_with_tail
                              hash_pattern const_pattern find_pattern
                              index indexasgn procarg0 kwargs]
      many_opt_node_children = %i[case rescue resbody ensure for when
                                  case_match in_pattern irange erange
                                  match_pattern match_pattern_p]

      ### Callbacks for above
      def_callback no_children
      def_callback opt_symbol_child, :skip, arity: 0..1
      def_callback opt_node_child, :nil?, arity: 0..1

      def_callback literal_child, :skip
      def_callback node_child, :always
      def_callback node_or_nil_child, :nil?

      def_callback symbol_then_opt_node, :skip, :nil?, arity: 1..2
      def_callback symbol_then_node_or_nil, :skip, :nil?
      def_callback node_then_opt_node, :always, :nil?

      def_callback many_symbol_children, :skip, arity_check: nil
      def_callback many_node_children, body: <<~RUBY
        node.children.each { |child| #{send_code} }
      RUBY
      def_callback many_opt_node_children,
                   body: <<~RUBY
                     node.children.each { |child| #{send_code} if child }
                   RUBY

      ### Other particular cases
      def_callback :const, :nil?, :skip
      def_callback :casgn, :nil?, :skip, :nil?, arity: 2..3
      def_callback :class, :always, :nil?, :nil?
      def_callback :def, :skip, :always, :nil?
      def_callback :op_asgn, :always, :skip, :always
      def_callback :if, :always, :nil?, :nil?
      def_callback :block, :always, :always, :nil?
      def_callback :numblock, :always, :skip, :nil?
      def_callback :defs, :always, :skip, :always, :nil?

      def_callback %i[send csend], body: <<~RUBY
        node.children.each_with_index do |child, i|
          next if i == 1

          #{send_code} if child
        end
      RUBY

      ### generic processing of any other node (forward compatibility)
      defined = instance_methods(false)
                .grep(/^on_/)
                .map { |s| s.to_s[3..].to_sym } # :on_foo => :foo

      to_define = ::Parser::Meta::NODE_TYPES.to_a
      to_define -= defined
      to_define -= %i[numargs ident] # transient
      to_define -= %i[blockarg_expr restarg_expr] # obsolete
      to_define -= %i[objc_kwarg objc_restarg objc_varargs] # mac_ruby
      def_callback to_define, body: <<~RUBY
        node.children.each do |child|
          next unless child.class == Node
          #{send_code}
        end
      RUBY
      MISSING = to_define if ENV['RUBOCOP_DEBUG']
    end
  end
end
