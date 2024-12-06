module PgQuery
  class ParserResult
    def param_refs # rubocop:disable Metrics/CyclomaticComplexity
      results = []

      treewalker! @tree do |_, _, node, location|
        case node
        when PgQuery::ParamRef
          # Ignore param refs inside type casts, as these are already handled
          next if location[-3..-1] == %i[type_cast arg param_ref]

          results << { 'location' => node.location,
                       'length' => param_ref_length(node) }
        when PgQuery::TypeCast
          next unless node.arg && node.type_name

          p = node.arg.param_ref
          t = node.type_name
          next unless p && t

          location = p.location
          typeloc  = t.location
          length   = param_ref_length(p)

          if location == -1
            location = typeloc
          elsif typeloc < location
            length += location - typeloc
            location = typeloc
          end

          results << { 'location' => location, 'length' => length, 'typename' => t.names.map { |n| n.string.sval } }
        end
      end

      results.sort_by! { |r| r['location'] }
      results
    end

    private

    def param_ref_length(paramref_node)
      if paramref_node.number == 0 # rubocop:disable Style/NumericPredicate
        1 # Actually a ? replacement character
      else
        ('$' + paramref_node.number.to_s).size
      end
    end
  end
end
