module Ancestry
  module MaterializedPathPg
    # Update descendants with new ancestry (after update)
    def update_descendants_with_new_ancestry
      # If enabled and node is existing and ancestry was updated and the new ancestry is sane ...
      if !ancestry_callbacks_disabled? && !new_record? && ancestry_changed? && sane_ancestor_ids?
        ancestry_column = ancestry_base_class.ancestry_column
        old_ancestry = generate_ancestry( path_ids_before_last_save )
        new_ancestry = generate_ancestry( path_ids )
        update_clause = [
          "#{ancestry_column} = regexp_replace(#{ancestry_column}, '^#{Regexp.escape(old_ancestry)}', '#{new_ancestry}')"
        ]

        if ancestry_base_class.respond_to?(:depth_cache_column) && respond_to?(ancestry_base_class.depth_cache_column)
          depth_cache_column = ancestry_base_class.depth_cache_column.to_s
          update_clause << "#{depth_cache_column} = length(regexp_replace(regexp_replace(ancestry, '^#{Regexp.escape(old_ancestry)}', '#{new_ancestry}'), '[^#{ancestry_base_class.ancestry_delimiter}]', '', 'g')) #{ancestry_base_class.ancestry_format == :materialized_path2 ? '-' : '+'} 1"
        end

        unscoped_descendants_before_save.update_all update_clause.join(', ')
      end
    end
  end
end
