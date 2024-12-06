# frozen_string_literal: true

require 'set'

module I18n::Tasks
  module Data::Tree
    # Any Enumerable that yields nodes can mix in this module
    module Traversal # rubocop:disable Metrics/ModuleLength
      def nodes(&block)
        depth_first(&block)
      end

      def leaves(&visitor)
        return to_enum(:leaves) unless visitor

        nodes do |node|
          visitor.yield(node) if node.leaf?
        end
        self
      end

      def levels(&block)
        return to_enum(:levels) unless block

        nodes = to_nodes
        unless nodes.empty?
          block.yield nodes
          if nodes.size == 1
            node = first
            node.children.levels(&block) if node.children?
          else
            Nodes.new(nodes: nodes.children).levels(&block)
          end
        end
        self
      end

      def breadth_first(&visitor)
        return to_enum(:breadth_first) unless visitor

        levels do |nodes|
          nodes.each { |node| visitor.yield(node) }
        end
        self
      end

      def depth_first(&visitor)
        return to_enum(:depth_first) unless visitor

        each do |node|
          visitor.yield node
          next unless node.children?

          node.children.each do |child|
            child.depth_first(&visitor)
          end
        end
        self
      end

      # @option root include root in full key
      def keys(root: false, &visitor)
        return to_enum(:keys, root: root) unless visitor

        leaves { |node| visitor.yield(node.full_key(root: root), node) }
        self
      end

      def key_names(root: false)
        keys(root: root).map { |key, _node| key }
      end

      def key_values(root: false)
        keys(root: root).map { |key, node| [key, node.value] }
      end

      def root_key_values(sort = false)
        result = keys(root: false).map { |key, node| [node.root.key, key, node.value] }
        result.sort! { |a, b| a[0] == b[0] ? a[1] <=> b[1] : a[0] <=> b[0] } if sort
        result
      end

      def root_key_value_data(sort = false)
        result = keys(root: false).map { |key, node| [node.root.key, key, node.value, node.data] }
        result.sort! { |a, b| a[0] == b[0] ? a[1] <=> b[1] : a[0] <=> b[0] } if sort
        result
      end

      #-- modify / derive

      # Select the nodes for which the block returns true. Pre-order traversal.
      # @return [Siblings] a new tree
      def select_nodes(&block)
        tree = Siblings.new
        each do |node|
          next unless block.yield(node)

          tree.append! node.derive(
            parent: tree.parent,
            children: (node.children.select_nodes(&block).to_a if node.children)
          )
        end
        tree
      end

      # Select the nodes for which the block returns true. Pre-order traversal.
      # @return [Siblings] self
      def select_nodes!(&block)
        to_remove = []
        each do |node|
          if block.yield(node)
            node.children&.select_nodes!(&block)
          else
            # removing during each is unsafe
            to_remove << node
          end
        end
        to_remove.each { |node| remove! node }
        self
      end

      # @return [Siblings]
      def select_keys(root: false, &block)
        matches = get_nodes_by_key_filter(root: root, &block)
        select_nodes do |node|
          matches.include?(node)
        end
      end

      # @return [Siblings]
      def select_keys!(root: false, &block)
        matches = get_nodes_by_key_filter(root: root, &block)
        select_nodes! do |node|
          matches.include?(node)
        end
      end

      # @return [Set<I18n::Tasks::Data::Tree::Node>]
      def get_nodes_by_key_filter(root: false, &block)
        matches = Set.new
        keys(root: root) do |full_key, node|
          if block.yield(full_key, node)
            node.walk_to_root do |p|
              break unless matches.add?(p)
            end
          end
        end
        matches
      end

      # @return [Siblings]
      def intersect_keys(other_tree, key_opts = {}, &block)
        if block
          select_keys(**key_opts.slice(:root)) do |key, node|
            other_node = other_tree[key]
            other_node && yield(key, node, other_node)
          end
        else
          select_keys(**key_opts.slice(:root)) { |key, _node| other_tree[key] }
        end
      end

      def grep_keys(match, opts = {})
        select_keys(**opts) do |full_key, _node|
          match === full_key # rubocop:disable Style/CaseEquality
        end
      end

      def set_each_value!(val_pattern, key_pattern = nil, &value_proc) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        value_proc ||= proc do |node|
          node_value = node.value
          next node_value if node.reference?

          human_key = ActiveSupport::Inflector.humanize(node.key.to_s)
          full_key = node.full_key
          default = (node.data[:occurrences] || []).detect { |o| o.default_arg.presence }.try(:default_arg)
          if default.is_a?(Hash)
            default.each_with_object({}) do |(k, v), h|
              h[k] = StringInterpolation.interpolate_soft(
                val_pattern,
                value: node_value,
                human_key: human_key,
                key: full_key,
                default: v,
                value_or_human_key: node_value.presence || human_key,
                value_or_default_or_human_key: node_value.presence || v || human_key
              )
            end
          else
            StringInterpolation.interpolate_soft(
              val_pattern,
              value: node_value,
              human_key: human_key,
              key: full_key,
              default: default,
              value_or_human_key: node_value.presence || human_key,
              value_or_default_or_human_key: node_value.presence || default || human_key
            )
          end
        end
        pattern_re = I18n::Tasks::KeyPatternMatching.compile_key_pattern(key_pattern) if key_pattern.present?
        keys.each do |key, node|
          next if pattern_re && key !~ pattern_re

          node.value = value_proc.call(node)
        end
        self
      end
    end
  end
end
