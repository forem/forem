module Ancestry
  module ClassMethods
    # Fetch tree node if necessary
    def to_node object
      if object.is_a?(self.ancestry_base_class)
        object
      else
        unscoped_where { |scope| scope.find(object.try(primary_key) || object) }
      end
    end

    # Scope on relative depth options
    def scope_depth depth_options, depth
      depth_options.inject(self.ancestry_base_class) do |scope, option|
        scope_name, relative_depth = option
        if [:before_depth, :to_depth, :at_depth, :from_depth, :after_depth].include? scope_name
          scope.send scope_name, depth + relative_depth
        else
          raise Ancestry::AncestryException.new(I18n.t("ancestry.unknown_depth_option", scope_name: scope_name))
        end
      end
    end

    # Orphan strategy writer
    def orphan_strategy= orphan_strategy
      # Check value of orphan strategy, only rootify, adopt, restrict or destroy is allowed
      if [:rootify, :adopt, :restrict, :destroy].include? orphan_strategy
        class_variable_set :@@orphan_strategy, orphan_strategy
      else
        raise Ancestry::AncestryException.new(I18n.t("ancestry.invalid_orphan_strategy"))
      end
    end


    # these methods arrange an entire subtree into nested hashes for easy navigation after database retrieval
    # the arrange method also works on a scoped class
    # the arrange method takes ActiveRecord find options
    # To order your hashes pass the order to the arrange method instead of to the scope

    # Get all nodes and sort them into an empty hash
    def arrange options = {}
      if (order = options.delete(:order))
        arrange_nodes self.ancestry_base_class.order(order).where(options)
      else
        arrange_nodes self.ancestry_base_class.where(options)
      end
    end

    # arranges array of nodes to a hierarchical hash
    #
    # @param nodes [Array[Node]] nodes to be arranged
    # @returns Hash{Node => {Node => {}, Node => {}}}
    # If a node's parent is not included, the node will be included as if it is a top level node
    def arrange_nodes(nodes)
      node_ids = Set.new(nodes.map(&:id))
      index = Hash.new { |h, k| h[k] = {} }

      nodes.each_with_object({}) do |node, arranged|
        children = index[node.id]
        index[node.parent_id][node] = children
        arranged[node] = children unless node_ids.include?(node.parent_id)
      end
    end

    # convert a hash of the form {node => children} to an array of nodes, child first
    #
    # @param arranged [Hash{Node => {Node => {}, Node => {}}}] arranged nodes
    # @returns [Array[Node]] array of nodes with the parent before the children
    def flatten_arranged_nodes(arranged, nodes = [])
      arranged.each do |node, children|
        nodes << node
        flatten_arranged_nodes(children, nodes) unless children.empty?
      end
      nodes
    end

     # Arrangement to nested array for serialization
     # You can also supply your own serialization logic using blocks
     # also allows you to pass the order just as you can pass it to the arrange method
    def arrange_serializable options={}, nodes=nil, &block
      nodes = arrange(options) if nodes.nil?
      nodes.map do |parent, children|
        if block_given?
          yield parent, arrange_serializable(options, children, &block)
        else
          parent.serializable_hash.merge 'children' => arrange_serializable(options, children)
        end
      end
    end

    def tree_view(column, data = nil)
      data = arrange unless data
      data.each do |parent, children|
        if parent.depth == 0
          puts parent[column]
        else
          num = parent.depth - 1
          indent = "   "*num
          puts " #{"|" if parent.depth > 1}#{indent}|_ #{parent[column]}"
        end
        tree_view(column, children) if children
      end
    end

    # Pseudo-preordered array of nodes.  Children will always follow parents,
    # This is deterministic unless the parents are missing *and* a sort block is specified
    def sort_by_ancestry(nodes, &block)
      arranged = nodes if nodes.is_a?(Hash)

      unless arranged
        presorted_nodes = nodes.sort do |a, b|
          rank = (a.public_send(ancestry_column) || ' ') <=> (b.public_send(ancestry_column) || ' ')
          rank = yield(a, b) if rank == 0 && block_given?
          rank
        end

        arranged = arrange_nodes(presorted_nodes)
      end

      flatten_arranged_nodes(arranged)
    end

    # Integrity checking
    # compromised tree integrity is unlikely without explicitly setting cyclic parents or invalid ancestry and circumventing validation
    # just in case, raise an AncestryIntegrityException if issues are detected
    # specify :report => :list to return an array of exceptions or :report => :echo to echo any error messages
    def check_ancestry_integrity! options = {}
      parents = {}
      exceptions = [] if options[:report] == :list

      unscoped_where do |scope|
        # For each node ...
        scope.find_each do |node|
          begin
            # ... check validity of ancestry column
            if !node.sane_ancestor_ids?
              raise Ancestry::AncestryIntegrityException.new(I18n.t("ancestry.invalid_ancestry_column",
                                                                    :node_id => node.id,
                                                                    :ancestry_column => "#{node.read_attribute node.ancestry_column}"
                                                                    ))
            end
            # ... check that all ancestors exist
            node.ancestor_ids.each do |ancestor_id|
              unless exists? ancestor_id
                raise Ancestry::AncestryIntegrityException.new(I18n.t("ancestry.reference_nonexistent_node",
                                                                      :node_id => node.id,
                                                                      :ancestor_id => ancestor_id
                                                                      ))
              end
            end
            # ... check that all node parents are consistent with values observed earlier
            node.path_ids.zip([nil] + node.path_ids).each do |node_id, parent_id|
              parents[node_id] = parent_id unless parents.has_key? node_id
              unless parents[node_id] == parent_id
                raise Ancestry::AncestryIntegrityException.new(I18n.t("ancestry.conflicting_parent_id",
                                                                      :node_id => node_id,
                                                                      :parent_id => parent_id || 'nil',
                                                                      :expected => parents[node_id] || 'nil'
                                                                      ))
              end
            end
          rescue Ancestry::AncestryIntegrityException => integrity_exception
            case options[:report]
              when :list then exceptions << integrity_exception
              when :echo then puts integrity_exception
              else raise integrity_exception
            end
          end
        end
      end
      exceptions if options[:report] == :list
    end

    # Integrity restoration
    def restore_ancestry_integrity!
      parent_ids = {}
      # Wrap the whole thing in a transaction ...
      self.ancestry_base_class.transaction do
        unscoped_where do |scope|
          # For each node ...
          scope.find_each do |node|
            # ... set its ancestry to nil if invalid
            if !node.sane_ancestor_ids?
              node.without_ancestry_callbacks do
                node.update_attribute :ancestor_ids, []
              end
            end
            # ... save parent id of this node in parent_ids array if it exists
            parent_ids[node.id] = node.parent_id if exists? node.parent_id

            # Reset parent id in array to nil if it introduces a cycle
            parent_id = parent_ids[node.id]
            until parent_id.nil? || parent_id == node.id
              parent_id = parent_ids[parent_id]
            end
            parent_ids[node.id] = nil if parent_id == node.id
          end

          # For each node ...
          scope.find_each do |node|
            # ... rebuild ancestry from parent_ids array
            ancestor_ids, parent_id = [], parent_ids[node.id]
            until parent_id.nil?
              ancestor_ids, parent_id = [parent_id] + ancestor_ids, parent_ids[parent_id]
            end
            node.without_ancestry_callbacks do
              node.update_attribute :ancestor_ids, ancestor_ids
            end
          end
        end
      end
    end

    # Build ancestry from parent ids for migration purposes
    def build_ancestry_from_parent_ids! column=:parent_id, parent_id = nil, ancestor_ids = []
      unscoped_where do |scope|
        scope.where(column => parent_id).find_each do |node|
          node.without_ancestry_callbacks do
            node.update_attribute :ancestor_ids, ancestor_ids
          end
          build_ancestry_from_parent_ids! column, node.id, ancestor_ids + [node.id]
        end
      end
    end

    # Rebuild depth cache if it got corrupted or if depth caching was just turned on
    def rebuild_depth_cache!
      raise Ancestry::AncestryException.new(I18n.t("ancestry.cannot_rebuild_depth_cache")) unless respond_to? :depth_cache_column

      self.ancestry_base_class.transaction do
        unscoped_where do |scope|
          scope.find_each do |node|
            node.update_attribute depth_cache_column, node.depth
          end
        end
      end
    end

    def unscoped_where
      yield self.ancestry_base_class.default_scoped.unscope(:where)
    end

    ANCESTRY_UNCAST_TYPES = [:string, :uuid, :text].freeze
    def primary_key_is_an_integer?
      if defined?(@primary_key_is_an_integer)
        @primary_key_is_an_integer
      else
        @primary_key_is_an_integer = !ANCESTRY_UNCAST_TYPES.include?(type_for_attribute(primary_key).type)
      end
    end
  end
end
