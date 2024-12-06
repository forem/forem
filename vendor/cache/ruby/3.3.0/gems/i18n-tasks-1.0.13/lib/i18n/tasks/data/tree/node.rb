# frozen_string_literal: true

require 'i18n/tasks/data/tree/traversal'
require 'i18n/tasks/data/tree/siblings'
module I18n::Tasks::Data::Tree
  class Node # rubocop:disable Metrics/ClassLength
    include Enumerable
    include Traversal

    attr_accessor :value
    attr_reader :key, :children, :parent

    # rubocop:disable Metrics/ParameterLists
    def initialize(key:, value: nil, data: nil, parent: nil, children: nil, warn_about_add_children_to_leaf: true)
      @key = key
      @key = @key.to_s.freeze if @key
      @value = value
      @data = data
      @parent = parent
      @warn_about_add_children_to_leaf = warn_about_add_children_to_leaf
      self.children = children if children
    end
    # rubocop:enable Metrics/ParameterLists

    def attributes
      { key: @key, value: @value, data: @data.try(:clone), parent: @parent, children: @children }
    end

    def derive(new_attr = {})
      self.class.new(**attributes.merge(new_attr))
    end

    def children=(children)
      @children = case children
                  when Siblings
                    children.parent == self ? children : children.derive(parent: self)
                  when NilClass
                    nil
                  else
                    Siblings.new(
                      nodes: children,
                      parent: self,
                      warn_about_add_children_to_leaf: @warn_about_add_children_to_leaf
                    )
                  end
      dirty!
    end

    def each(&block)
      return to_enum(:each) { 1 } unless block

      block.yield(self)
      self
    end

    def value_or_children_hash
      leaf? ? value : children.try(:to_hash)
    end

    def leaf?
      !children
    end

    # a node with key nil is considered Empty. this is to allow for using these nodes instead of nils
    def root?
      !parent?
    end

    def parent?
      !parent.nil?
    end

    def children?
      children && !children.empty?
    end

    def data
      @data ||= {}
    end

    def data?
      @data.present?
    end

    def reference?
      value.is_a?(Symbol)
    end

    def get(key)
      children.get(key)
    end

    alias [] get

    # append and reparent nodes
    def append!(nodes)
      if @children
        @children.merge!(nodes)
      else
        @children = Siblings.new(nodes: nodes, parent: self)
      end
      self
    end

    def append(nodes)
      derive.append!(nodes)
    end

    def full_key(root: true)
      @full_key ||= {}
      @full_key[root] ||= "#{"#{parent.full_key(root: root)}." if parent? && (root || parent.parent?)}#{key}"
    end

    def walk_to_root(&visitor)
      return to_enum(:walk_to_root) unless visitor

      visitor.yield self
      parent.walk_to_root(&visitor) if parent?
    end

    def root
      p = nil
      walk_to_root { |node| p = node }
      p
    end

    def walk_from_root(&visitor)
      return to_enum(:walk_from_root) unless visitor

      walk_to_root.reverse_each do |node|
        visitor.yield node
      end
    end

    def set(full_key, node)
      (@children ||= Siblings.new(parent: self)).set(full_key, node)
      dirty!
      node
    end

    alias []= set

    def to_nodes
      Nodes.new([self])
    end

    def to_siblings
      parent&.children || Siblings.new(nodes: [self])
    end

    def to_hash(sort = false)
      (@hash ||= {})[sort] ||= begin
        children_hash = children ? children.to_hash(sort) : {}
        if key.nil?
          children_hash
        elsif leaf?
          { key => value }
        else
          { key => children_hash }
        end
      end
    end

    delegate :to_json, to: :to_hash
    delegate :to_yaml, to: :to_hash

    def inspect(level = 0)
      label = if key.nil?
                Rainbow('∅').faint
              else
                [Rainbow(key).color(1 + (level % 15)),
                 (": #{format_value_for_inspect(value)}" if leaf?),
                 (" #{data}" if data?)].compact.join
              end
      ['  ' * level, label, ("\n#{children.map { |c| c.inspect(level + 1) }.join("\n")}" if children?)].compact.join
    end

    def format_value_for_inspect(value)
      if value.is_a?(Symbol)
        "#{Rainbow('⮕ ').bright.yellow}#{Rainbow(value).yellow}"
      else
        Rainbow(value).cyan
      end
    end

    protected

    def dirty!
      @hash = nil
      @full_key = nil
    end

    class << self
      # value can be a nested hash
      def from_key_value(key, value)
        Node.new(key: key.try(:to_s)).tap do |node|
          if value.is_a?(Hash)
            node.children = Siblings.from_nested_hash(value)
          else
            node.value = value
          end
        end
      end
    end
  end
end
