module Events
  class SyncMemberships
    def self.sync_parents(event, parent_ids)
      new(event).sync_both(parent_ids: parent_ids, child_entries: nil)
    end

    def self.sync_children(event, child_entries)
      new(event).sync_both(parent_ids: nil, child_entries: child_entries)
    end

    def self.sync_both(event, parent_ids: nil, child_entries: nil)
      new(event).sync_both(parent_ids: parent_ids, child_entries: child_entries)
    end

    def initialize(event)
      @event = event
    end

    # Coordinates both parent and child synchronization in one transaction:
    # removes obsolete edges in both directions BEFORE validating and inserting
    # new edges so valid direction reversals (e.g., E->C into C->E) succeed
    # atomically while rolling back cleanly if any replacement edge is invalid.
    def sync_both(parent_ids: nil, child_entries: nil)
      normalized_parents = parent_ids.nil? ? nil : normalize_id_list(parent_ids)
      normalized_children = child_entries.nil? ? nil : normalize_child_entries(child_entries)
      return false if @event.errors.any?
      return true if normalized_parents.nil? && normalized_children.nil?

      return false unless validate_referenced_events_exist(normalized_parents, normalized_children)

      ActiveRecord::Base.transaction(requires_new: true) do
        EventMembership.acquire_hierarchy_write_lock!

        current_parents = normalized_parents.nil? ? nil : @event.parent_event_memberships.index_by(&:parent_event_id)
        current_children = normalized_children.nil? ? nil : @event.child_event_memberships.index_by(&:child_event_id)

        apply_removals(normalized_parents, current_parents, normalized_children, current_children)
        apply_parent_additions(normalized_parents, current_parents)
        apply_child_upserts(normalized_children, current_children)
      end

      @event.errors.empty?
    end

    private

    def validate_referenced_events_exist(parent_ids, child_entries)
      if parent_ids.present?
        existing_parent_ids = Event.where(id: parent_ids).ids
        missing_parents = parent_ids - existing_parent_ids
        if missing_parents.any?
          @event.errors.add(:base, I18n.t("models.event_membership.parent_not_found", ids: missing_parents.join(", ")))
        end
      end

      if child_entries.present?
        child_ids = child_entries.pluck(:child_event_id)
        existing_child_ids = Event.where(id: child_ids).ids
        missing_children = child_ids - existing_child_ids
        if missing_children.any?
          @event.errors.add(:base, I18n.t("models.event_membership.child_not_found", ids: missing_children.join(", ")))
        end
      end

      @event.errors.empty?
    end

    def apply_removals(parent_ids, current_parents, child_entries, current_children)
      unless parent_ids.nil?
        to_remove_parents = current_parents.keys - parent_ids
        @event.parent_event_memberships.where(parent_event_id: to_remove_parents).destroy_all if to_remove_parents.any?
      end

      return if child_entries.nil?

      child_ids = child_entries.pluck(:child_event_id)
      to_remove_children = current_children.keys - child_ids
      @event.child_event_memberships.where(child_event_id: to_remove_children).destroy_all if to_remove_children.any?
    end

    def apply_parent_additions(parent_ids, current_parents)
      return if parent_ids.nil?

      to_add = parent_ids - current_parents.keys
      to_add.each do |parent_id|
        next_pos = (EventMembership.where(parent_event_id: parent_id).maximum(:position) || -1) + 1
        membership = @event.parent_event_memberships.build(parent_event_id: parent_id, position: next_pos)
        next if membership.save

        copy_errors(membership)
        raise ActiveRecord::Rollback
      end
    end

    def apply_child_upserts(child_entries, current_children)
      return if child_entries.nil?

      child_entries.each_with_index do |entry, index|
        membership = current_children[entry[:child_event_id]] ||
          @event.child_event_memberships.build(child_event_id: entry[:child_event_id])
        membership.position = entry.key?(:position) ? entry[:position] : index
        membership.role = entry[:role] if entry.key?(:role)
        membership.featured = entry[:featured] if entry.key?(:featured)

        next if membership.save

        copy_errors(membership)
        raise ActiveRecord::Rollback
      end
    end

    def normalize_id_list(raw_ids)
      return if raw_ids.nil?

      Array(raw_ids).filter_map do |val|
        str = val.to_s.strip
        next if str.blank?

        Integer(str, 10)
      rescue ArgumentError
        @event.errors.add(:base, I18n.t("models.event_membership.invalid_event_id", value: str))
        nil
      end.uniq
    end

    def normalize_child_entries(raw_entries)
      seen = Set.new
      Array(raw_entries).each_with_index.filter_map do |item, index|
        entry = if item.is_a?(Hash) || item.respond_to?(:to_h)
                  hash = item.to_h.with_indifferent_access
                  child_id = parse_int(hash[:child_event_id] || hash[:event_id] || hash[:id])
                  next unless child_id

                  attrs = { child_event_id: child_id }
                  attrs[:position] = hash[:position].to_i if hash.key?(:position) && hash[:position].present?
                  attrs[:role] = hash[:role] if hash.key?(:role)
                  attrs[:featured] = ActiveModel::Type::Boolean.new.cast(hash[:featured]) if hash.key?(:featured)
                  attrs
                else
                  child_id = parse_int(item)
                  next unless child_id

                  { child_event_id: child_id, position: index }
                end

        next if seen.include?(entry[:child_event_id])

        seen.add(entry[:child_event_id])
        entry
      end
    end

    def parse_int(value)
      str = value.to_s.strip
      return if str.blank?

      Integer(str, 10)
    rescue ArgumentError
      @event.errors.add(:base, I18n.t("models.event_membership.invalid_event_id", value: str))
      nil
    end

    def copy_errors(membership)
      membership.errors.full_messages.each do |message|
        @event.errors.add(:base, message)
      end
    end
  end
end
