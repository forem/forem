module Events
  class SubEventSchedule
    attr_reader :event, :at, :memberships, :live_memberships, :upcoming_memberships, :past_memberships

    def initialize(event, include_drafts: false, at: Time.current, memberships: nil)
      @event = event
      @include_drafts = include_drafts
      @at = at
      @memberships = filter_memberships(memberships || load_memberships)
      partition_memberships
    end

    def any?
      @memberships.any?
    end

    def empty?
      @memberships.empty?
    end

    def live?
      @live_memberships.any?
    end

    def upcoming_only?
      @live_memberships.empty? && @upcoming_memberships.any?
    end

    def all_ended?
      @live_memberships.empty? && @upcoming_memberships.empty? && @past_memberships.any?
    end

    def hero_state
      return :live if live?
      return :upcoming if upcoming_only?
      return :past if all_ended?

      :empty
    end

    def hero_membership
      @live_memberships.first || @upcoming_memberships.first
    end

    def hero_event
      hero_membership&.child_event
    end

    def other_live_memberships
      @live_memberships.drop(1)
    end

    def upcoming_by_day
      @upcoming_by_day ||= group_by_day(@upcoming_memberships)
    end

    def past_by_day
      @past_by_day ||= group_by_day(@past_memberships)
    end

    def roles
      @roles ||= @memberships.filter_map { |membership| membership.role.presence }.uniq
    end

    def event_types
      @event_types ||= @memberships.map { |membership| membership.child_event.type_of }.uniq
    end

    def all_events
      @all_events ||= @memberships.map(&:child_event)
    end

    def total_count
      @memberships.size
    end

    def live_count
      @live_memberships.size
    end

    def upcoming_count
      @upcoming_memberships.size
    end

    def past_count
      @past_memberships.size
    end

    private

    def load_memberships
      @event.child_event_memberships
        .ordered
        .includes(child_event: %i[page organization user])
        .to_a
    end

    def filter_memberships(raw_memberships)
      raw_memberships.select do |membership|
        child = membership.child_event
        child.present? && (@include_drafts || child.published?)
      end
    end

    def partition_memberships
      live = []
      upcoming = []
      past = []

      @memberships.each do |membership|
        child = membership.child_event
        if child.live?(@at)
          live << membership
        elsif child.upcoming?(@at)
          upcoming << membership
        else
          past << membership
        end
      end

      @live_memberships = live.sort_by do |m|
        child = m.child_event
        [
          m.featured? ? 0 : 1,
          child.primary_stream_url.present? ? 0 : 1,
          child.live_stream? ? 0 : 1,
          m.position,
          child.start_time,
          m.id,
        ]
      end

      @upcoming_memberships = upcoming.sort_by do |m|
        child = m.child_event
        [child.start_time, m.featured? ? 0 : 1, m.position, m.id]
      end

      @past_memberships = past.sort_by do |m|
        child = m.child_event
        [child.start_time, m.position, m.id]
      end
    end

    def group_by_day(list)
      tz = @event.time_zone
      list.group_by { |membership| membership.child_event.start_time.in_time_zone(tz).to_date }
    end
  end
end
