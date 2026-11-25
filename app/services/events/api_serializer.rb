module Events
  class ApiSerializer
    def self.serialize_collection(events, include_drafts: false, include_hierarchy: false, at: Time.current)
      new(include_drafts: include_drafts, at: at).serialize_collection(
        events, include_hierarchy: include_hierarchy
      )
    end

    def self.serialize_single(event, include_drafts: false, at: Time.current)
      new(include_drafts: include_drafts, at: at).serialize_single(event)
    end

    def self.serialize_membership(membership, at: Time.current)
      new(include_drafts: true, at: at).serialize_membership(membership)
    end

    def self.serialize_memberships_payload(event, include_drafts: false, at: Time.current)
      new(include_drafts: include_drafts, at: at).serialize_memberships_payload(event)
    end

    def initialize(include_drafts: false, at: Time.current)
      @include_drafts = include_drafts
      @at = at
    end

    def serialize_collection(events, include_hierarchy: false)
      event_list = events.to_a
      return [] if event_list.empty?

      ids = event_list.map(&:id)
      child_memberships_by_parent = load_memberships_by(:parent_event_id, ids)
      parent_memberships_by_child = load_memberships_by(:child_event_id, ids)

      related_ids = collect_related_ids(child_memberships_by_parent, parent_memberships_by_child)
      related_events_by_id = load_visible_related_events(related_ids)

      event_list.map do |event|
        child_memberships = visible_memberships(
          child_memberships_by_parent[event.id], related_events_by_id, :child_event_id
        )
        parent_memberships = visible_memberships(
          parent_memberships_by_child[event.id], related_events_by_id, :parent_event_id
        )

        payload = event.as_json
        payload["parent_event_ids"] = parent_memberships.map(&:parent_event_id)
        payload["sub_event_ids"] = child_memberships.map(&:child_event_id)

        if include_hierarchy
          attach_hierarchy_details(payload, event, child_memberships, parent_memberships, related_events_by_id)
        end

        payload
      end
    end

    def serialize_single(event)
      serialize_collection([event], include_hierarchy: true).first
    end

    def serialize_membership(membership)
      child = membership.child_event
      {
        id: membership.id,
        parent_event_id: membership.parent_event_id,
        child_event_id: membership.child_event_id,
        position: membership.position,
        role: membership.role,
        featured: membership.featured,
        created_at: membership.created_at,
        updated_at: membership.updated_at,
        child_event: child ? summarize_event(child) : nil
      }
    end

    def serialize_memberships_payload(event)
      schedule = event.sub_event_schedule(include_drafts: @include_drafts, at: @at)
      parent_memberships = event.parent_event_memberships
        .ordered
        .includes(:parent_event)
        .select { |m| m.parent_event.present? && (@include_drafts || m.parent_event.published?) }

      hero = schedule.hero_membership
      {
        event_id: event.id,
        hero_state: schedule.hero_state.to_s,
        hero_sub_event: hero ? serialize_sub_event_entry(hero, hero.child_event) : nil,
        live_sub_events: schedule.live_memberships.map { |m| serialize_sub_event_entry(m, m.child_event) },
        upcoming_sub_events: schedule.upcoming_memberships.map { |m| serialize_sub_event_entry(m, m.child_event) },
        past_sub_events: schedule.past_memberships.map { |m| serialize_sub_event_entry(m, m.child_event) },
        sub_events: schedule.memberships.map { |m| serialize_sub_event_entry(m, m.child_event) },
        parent_events: parent_memberships.map { |m| serialize_parent_event_entry(m, m.parent_event) }
      }
    end

    private

    def load_memberships_by(column, ids)
      EventMembership.where(column => ids).ordered.group_by(&column)
    end

    def collect_related_ids(child_by_parent, parent_by_child)
      ids = []
      child_by_parent.each_value { |list| list.each { |m| ids << m.child_event_id } }
      parent_by_child.each_value { |list| list.each { |m| ids << m.parent_event_id } }
      ids.uniq
    end

    def load_visible_related_events(ids)
      return {} if ids.empty?

      scope = Event.where(id: ids)
      scope = scope.published unless @include_drafts
      scope.index_by(&:id)
    end

    def visible_memberships(memberships, related_events_by_id, target_key)
      Array(memberships).select { |m| related_events_by_id.key?(m.public_send(target_key)) }
    end

    def attach_hierarchy_details(payload, event, child_memberships, parent_memberships, related_events_by_id)
      hydrated_children = child_memberships.map do |membership|
        membership.association(:child_event).target = related_events_by_id[membership.child_event_id]
        membership
      end

      schedule = event.sub_event_schedule(
        include_drafts: @include_drafts,
        at: @at,
        memberships: hydrated_children,
      )

      payload["parent_events"] = parent_memberships.map do |membership|
        serialize_parent_event_entry(membership, related_events_by_id[membership.parent_event_id])
      end
      payload["sub_events"] = hydrated_children.map do |membership|
        serialize_sub_event_entry(membership, related_events_by_id[membership.child_event_id])
      end
      hero = schedule.hero_membership
      payload["schedule"] = {
        hero_state: schedule.hero_state.to_s,
        hero_sub_event: hero ? serialize_sub_event_entry(hero, hero.child_event) : nil,
        live_count: schedule.live_count,
        upcoming_count: schedule.upcoming_count,
        past_count: schedule.past_count,
        total_count: schedule.total_count
      }
    end

    def serialize_sub_event_entry(membership, child_event)
      summarize_event(child_event).merge(
        membership_id: membership.id,
        position: membership.position,
        role: membership.role,
        featured: membership.featured,
      )
    end

    def serialize_parent_event_entry(membership, parent_event)
      summarize_event(parent_event).merge(
        membership_id: membership.id,
        position: membership.position,
        role: membership.role,
        featured: membership.featured,
      )
    end

    def summarize_event(event)
      {
        id: event.id,
        title: event.title,
        event_name_slug: event.event_name_slug,
        event_variation_slug: event.event_variation_slug,
        path: event.path,
        description: event.description,
        type_of: event.type_of,
        start_time: event.start_time,
        end_time: event.end_time,
        published: event.published,
        primary_stream_url: event.primary_stream_url,
        bg_color_hex: event.bg_color_hex,
        cover_image_url: event.cover_image.presence&.url,
        status: timing_status(event)
      }
    end

    def timing_status(event)
      return "live" if event.live?(@at)
      return "upcoming" if event.upcoming?(@at)

      "ended"
    end
  end
end
