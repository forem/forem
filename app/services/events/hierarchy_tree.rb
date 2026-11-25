module Events
  class HierarchyTree
    DEFAULT_PER_PAGE = 25

    Node = Data.define(:event, :membership, :children, :depth, :parent_count, :pages_count)

    attr_reader :roots, :paginated_scope, :total_events_count, :total_roots_count, :total_sub_links_count

    def initialize(scope: Event.all, page: 1, per_page: DEFAULT_PER_PAGE, flat: false, filtered: false)
      @base_scope = scope
      @page = page
      @per_page = per_page
      @flat = flat
      @filtered = filtered
      @total_events_count = Event.count
      @total_sub_links_count = EventMembership.count
      build_tree
    end

    def flat?
      @flat
    end

    private

    def build_tree
      if @flat
        build_flat_nodes
      else
        build_hierarchical_nodes
      end
    end

    def build_flat_nodes
      ordered = @base_scope.order(created_at: :desc)
      @paginated_scope = ordered.page(@page).per(@per_page)
      @total_roots_count = @paginated_scope.total_count
      events = @paginated_scope.to_a
      visible_ids = events.map(&:id)
      parent_counts, pages_counts = batch_counts(visible_ids)

      @roots = events.map do |event|
        Node.new(
          event: event,
          membership: nil,
          children: [],
          depth: 0,
          parent_count: parent_counts[event.id] || 0,
          pages_count: pages_counts[event.id] || 0,
        )
      end
    end

    def build_hierarchical_nodes
      child_event_ids_subquery = EventMembership.select(:child_event_id)

      root_relation = if @filtered
                        filtered_root_relation(child_event_ids_subquery)
                      else
                        @base_scope.where.not(id: child_event_ids_subquery)
                      end

      @paginated_scope = root_relation.order(created_at: :desc).page(@page).per(@per_page)
      @total_roots_count = @paginated_scope.total_count
      root_events = @paginated_scope.to_a

      memberships_by_parent, events_by_id = load_descendant_graph(root_events)
      all_visible_ids = events_by_id.keys
      parent_counts, pages_counts = batch_counts(all_visible_ids)

      @roots = root_events.map do |root_event|
        build_node(
          root_event,
          membership: nil,
          depth: 0,
          visited: Set.new([root_event.id]),
          memberships_by_parent: memberships_by_parent,
          events_by_id: events_by_id,
          parent_counts: parent_counts,
          pages_counts: pages_counts,
        )
      end
    end

    def filtered_root_relation(child_event_ids_subquery)
      matching_ids = @base_scope.ids
      return Event.none if matching_ids.empty?

      # Include matching events that are either top-level roots OR whose parents
      # aren't already in the matching set so filtered sub-events are never hidden.
      matched_parents_of_matches = EventMembership
        .where(child_event_id: matching_ids, parent_event_id: matching_ids)
        .select(:child_event_id)

      Event.where(id: matching_ids).where.not(id: matched_parents_of_matches)
        .or(Event.where(id: matching_ids).where.not(id: child_event_ids_subquery))
    end

    def load_descendant_graph(root_events)
      events_by_id = root_events.index_by(&:id)
      memberships_by_parent = Hash.new { |h, k| h[k] = [] }
      frontier_ids = root_events.map(&:id)
      seen_parent_ids = Set.new

      EventMembership::MAX_DEPTH.times do
        frontier_ids -= seen_parent_ids.to_a
        break if frontier_ids.empty?

        seen_parent_ids.merge(frontier_ids)
        memberships = EventMembership.where(parent_event_id: frontier_ids).ordered.to_a
        break if memberships.empty?

        next_child_ids = []
        memberships.each do |membership|
          memberships_by_parent[membership.parent_event_id] << membership
          next_child_ids << membership.child_event_id unless events_by_id.key?(membership.child_event_id)
        end

        if next_child_ids.any?
          Event.where(id: next_child_ids.uniq).find_each do |child_event|
            events_by_id[child_event.id] = child_event
          end
        end

        frontier_ids = memberships.map(&:child_event_id).uniq
      end

      [memberships_by_parent, events_by_id]
    end

    def build_node(event, membership:, depth:, visited:, memberships_by_parent:, events_by_id:,
                   parent_counts:, pages_counts:)
      child_nodes = (memberships_by_parent[event.id] || []).filter_map do |child_membership|
        child_event = events_by_id[child_membership.child_event_id]
        next if child_event.nil? || visited.include?(child_event.id) || depth >= EventMembership::MAX_DEPTH

        build_node(
          child_event,
          membership: child_membership,
          depth: depth + 1,
          visited: visited | [child_event.id],
          memberships_by_parent: memberships_by_parent,
          events_by_id: events_by_id,
          parent_counts: parent_counts,
          pages_counts: pages_counts,
        )
      end

      Node.new(
        event: event,
        membership: membership,
        children: child_nodes,
        depth: depth,
        parent_count: parent_counts[event.id] || 0,
        pages_count: pages_counts[event.id] || 0,
      )
    end

    def batch_counts(event_ids)
      return [{}, {}] if event_ids.empty?

      parent_counts = EventMembership.where(child_event_id: event_ids).group(:child_event_id).count
      pages_counts = Page.where(event_id: event_ids).group(:event_id).count
      [parent_counts, pages_counts]
    end
  end
end
