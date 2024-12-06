# frozen_string_literal: true

module I18n::Tasks
  module References
    # Given a raw usage tree and a tree of reference keys in the data, return 3 trees:
    # 1. Raw references -- a subset of the usages tree with keys that are reference key usages.
    # 2. Resolved references -- all the used references in their fully resolved form.
    # 3. Reference keys -- all the used reference keys.
    def process_references(usages,
                           data_refs = merge_reference_trees(data_forest.select_keys { |_, node| node.reference? }))
      fail ArgumentError, 'usages must be a Data::Tree::Instance' unless usages.is_a?(Data::Tree::Siblings)
      fail ArgumentError, 'all_references must be a Data::Tree::Instance' unless data_refs.is_a?(Data::Tree::Siblings)

      raw_refs = empty_forest
      resolved_refs = empty_forest
      refs = empty_forest
      data_refs.key_to_node.each do |ref_key_part, ref_node|
        usages.each do |usage_node|
          next unless usage_node.key == ref_key_part

          if ref_node.leaf?
            process_leaf!(ref_node, usage_node, raw_refs, resolved_refs, refs)
          else
            process_non_leaf!(ref_node, usage_node, raw_refs, resolved_refs, refs)
          end
        end
      end
      [raw_refs, resolved_refs, refs]
    end

    private

    # @param [I18n::Tasks::Data::Tree::Node] ref
    # @param [I18n::Tasks::Data::Tree::Node] usage
    # @param [I18n::Tasks::Data::Tree::Siblings] raw_refs
    # @param [I18n::Tasks::Data::Tree::Siblings] resolved_refs
    # @param [I18n::Tasks::Data::Tree::Siblings] refs
    def process_leaf!(ref, usage, raw_refs, resolved_refs, refs)
      refs.merge_node!(Data::Tree::Node.new(key: ref.key, data: usage.data)) unless refs.key_to_node.key?(ref.key)
      new_resolved_refs = Data::Tree::Siblings.from_key_names([ref.value.to_s]) do |_, resolved_node|
        raw_refs.merge_node!(usage)
        if usage.leaf?
          resolved_node.data.merge!(usage.data)
        else
          resolved_node.children = usage.children
        end
        resolved_node.leaves { |node| node.data[:ref_info] = [ref.full_key, ref.value.to_s] }
      end
      add_occurences! refs.key_to_node[ref.key].data, new_resolved_refs
      resolved_refs.merge! new_resolved_refs
    end

    # @param [Hash] ref_data
    # @param [I18n::Tasks::Data::Tree::Siblings] new_resolved_refs
    def add_occurences!(ref_data, new_resolved_refs)
      ref_data[:occurrences] ||= []
      new_resolved_refs.leaves do |leaf|
        ref_data[:occurrences].concat(leaf.data[:occurrences] || [])
      end
      ref_data[:occurrences].sort_by!(&:path)
      ref_data[:occurrences].uniq!
    end

    # @param [I18n::Tasks::Data::Tree::Node] ref
    # @param [I18n::Tasks::Data::Tree::Node] usage
    # @param [I18n::Tasks::Data::Tree::Siblings] raw_refs
    # @param [I18n::Tasks::Data::Tree::Siblings] resolved_refs
    # @param [I18n::Tasks::Data::Tree::Siblings] refs
    def process_non_leaf!(ref, usage, raw_refs, resolved_refs, refs)
      child_raw_refs, child_resolved_refs, child_refs = process_references(usage.children, ref.children)
      raw_refs.merge_node! Data::Tree::Node.new(key: ref.key, children: child_raw_refs) unless child_raw_refs.empty?
      resolved_refs.merge! child_resolved_refs
      refs.merge_node! Data::Tree::Node.new(key: ref.key, children: child_refs) unless child_refs.empty?
    end

    # Given a forest of references, merge trees into one tree, ensuring there are no conflicting references.
    # @param roots [I18n::Tasks::Data::Tree::Siblings]
    # @return [I18n::Tasks::Data::Tree::Siblings]
    def merge_reference_trees(roots)
      roots.inject(empty_forest) do |forest, root|
        root.keys do |full_key, node|
          if full_key == node.value.to_s
            log_warn(
              "Self-referencing key #{node.full_key(root: false).inspect} in #{node.data[:locale].inspect}"
            )
          end
        end
        forest.merge!(
          root.children,
          on_leaves_merge: lambda do |node, other|
            if node.value != other.value
              log_warn(
                'Conflicting references: ' \
                "#{node.full_key(root: false)} ⮕ #{node.value} in #{node.data[:locale]}, " \
                "but ⮕ #{other.value} in #{other.data[:locale]}"
              )
            end
          end
        )
      end
    end
  end
end
