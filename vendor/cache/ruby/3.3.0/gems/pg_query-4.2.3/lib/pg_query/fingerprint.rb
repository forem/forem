require 'digest'

module PgQuery
  class ParserResult
    def fingerprint
      hash = FingerprintSubHash.new
      fingerprint_tree(hash)
      fp = PgQuery.hash_xxh3_64(hash.parts.join, FINGERPRINT_VERSION)
      format('%016x', fp)
    end

    private

    FINGERPRINT_VERSION = 3

    class FingerprintSubHash
      attr_reader :parts

      def initialize
        @parts = []
      end

      def update(part)
        @parts << part
      end

      def flush_to(hash)
        parts.each do |part|
          hash.update part
        end
      end
    end

    def ignored_fingerprint_value?(val)
      [nil, 0, false, [], ''].include?(val)
    end

    def fingerprint_value(val, hash, parent_node_name, parent_field_name, need_to_write_name) # rubocop:disable Metrics/CyclomaticComplexity
      subhash = FingerprintSubHash.new

      if val.is_a?(Google::Protobuf::RepeatedField)
        # For lists that have exactly one untyped node, just output the parent field (if needed) and return
        if val.length == 1 && val[0].is_a?(Node) && val[0].node.nil?
          hash.update(parent_field_name) if need_to_write_name
          return
        end
        fingerprint_list(val, subhash, parent_node_name, parent_field_name)
      elsif val.is_a?(List)
        fingerprint_list(val.items, subhash, parent_node_name, parent_field_name)
      elsif val.is_a?(Google::Protobuf::MessageExts)
        fingerprint_node(val, subhash, parent_node_name, parent_field_name)
      elsif !ignored_fingerprint_value?(val)
        subhash.update val.to_s
      end

      return if subhash.parts.empty?

      hash.update(parent_field_name) if need_to_write_name
      subhash.flush_to(hash)
    end

    def ignored_node_type?(node)
      [A_Const, Alias, ParamRef, SetToDefault, IntList, OidList].include?(node.class) ||
        node.is_a?(TypeCast) && (node.arg.node == :a_const || node.arg.node == :param_ref)
    end

    def node_protobuf_field_name_to_json_name(node_class, field)
      node_class.descriptor.find { |d| d.name == field.to_s }.json_name
    end

    def fingerprint_node(node, hash, parent_node_name = nil, parent_field_name = nil) # rubocop:disable Metrics/CyclomaticComplexity
      return if ignored_node_type?(node)

      if node.is_a?(Node)
        return if node.node.nil?
        node_val = node[node.node.to_s]
        unless ignored_node_type?(node_val)
          unless node_val.is_a?(List)
            postgres_node_name = node_protobuf_field_name_to_json_name(node.class, node.node)
            hash.update(postgres_node_name)
          end
          fingerprint_value(node_val, hash, parent_node_name, parent_field_name, false)
        end
        return
      end

      postgres_node_name = node.class.name.split('::').last

      node.to_h.keys.sort.each do |field_name|
        val = node[field_name.to_s]

        postgres_field_name = node_protobuf_field_name_to_json_name(node.class, field_name)

        case postgres_field_name
        when 'location'
          next
        when 'name'
          next if [PrepareStmt, ExecuteStmt, DeallocateStmt, FunctionParameter].include?(node.class)
          next if node.is_a?(ResTarget) && parent_node_name == 'SelectStmt' && parent_field_name == 'targetList'
        when 'gid', 'savepoint_name'
          next if node.is_a?(TransactionStmt)
        when 'options'
          next if [TransactionStmt, CreateFunctionStmt].include?(node.class)
        when 'portalname'
          next if [DeclareCursorStmt, FetchStmt, ClosePortalStmt].include?(node.class)
        when 'conditionname'
          next if [ListenStmt, UnlistenStmt, NotifyStmt].include?(node.class)
        when 'args'
          next if node.is_a?(DoStmt)
        when 'relname'
          next if node.is_a?(RangeVar) && node.relpersistence == 't'
          if node.is_a?(RangeVar)
            fingerprint_value(val.gsub(/\d{2,}/, ''), hash, postgres_node_name, postgres_field_name, true)
            next
          end
        when 'stmt_len'
          next if node.is_a?(RawStmt)
        when 'stmt_location'
          next if node.is_a?(RawStmt)
        when 'kind'
          if node.is_a?(A_Expr) && (val == :AEXPR_OP_ANY || val == :AEXPR_IN)
            fingerprint_value(:AEXPR_OP, hash, postgres_node_name, postgres_field_name, true)
            next
          end
        # libpg_query still outputs `str` parts when print a string node. Here we override that to
        # the expected field name of `sval`.
        when 'sval', 'fval', 'bsval'
          postgres_field_name = 'str' if node.is_a?(String) || node.is_a?(BitString) || node.is_a?(Float)
        end

        fingerprint_value(val, hash, postgres_node_name, postgres_field_name, true)
      end
    end

    def fingerprint_list(values, hash, parent_node_name, parent_field_name)
      if %w[fromClause targetList cols rexpr valuesLists args].include?(parent_field_name)
        values_subhashes = values.map do |val|
          subhash = FingerprintSubHash.new
          fingerprint_value(val, subhash, parent_node_name, parent_field_name, false)
          subhash
        end

        values_subhashes.uniq!(&:parts)
        values_subhashes.sort_by! { |s| PgQuery.hash_xxh3_64(s.parts.join, FINGERPRINT_VERSION) }

        values_subhashes.each do |subhash|
          subhash.flush_to(hash)
        end
      else
        values.each do |val|
          fingerprint_value(val, hash, parent_node_name, parent_field_name, false)
        end
      end
    end

    def fingerprint_tree(hash)
      @tree.stmts.each do |node|
        hash.update 'RawStmt'
        fingerprint_node(node, hash)
      end
    end
  end
end
