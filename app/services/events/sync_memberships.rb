module Events
  class SyncMemberships
    def self.sync_parents(event, parent_ids)
      new(event).sync_parents(parent_ids)
    end

    def self.sync_children(event, child_entries)
      new(event).sync_children(child_entries)
    end

    def initialize(event)
      @event = event
    end

    def sync_parents(raw_parent_ids)
      ids = normalize_id_list(raw_parent_ids)
      return true if ids.nil?
      return false if @event.errors.any?

      existing_parent_ids = Event.where(id: ids).ids
      missing_ids = ids - existing_parent_ids
      if missing_ids.any?
        @event.errors.add(:base, I18n.t("models.event_membership.parent_not_found", ids: missing_ids.join(", ")))
        return false
      end

      current_memberships = @event.parent_event_memberships.index_by(&:parent_event_id)
      to_remove = current_memberships.keys - ids
      to_add = ids - current_memberships.keys

      ActiveRecord::Base.transaction(requires_new: true) do
        if to_remove.any?
          @event.parent_event_memberships.where(parent_event_id: to_remove).destroy_all
        end

        to_add.each do |parent_id|
          next_pos = (EventMembership.where(parent_event_id: parent_id).maximum(:position) || -1) + 1
          membership = @event.parent_event_memberships.build(parent_event_id: parent_id, position: next_pos)
          next if membership.save

          copy_errors(membership)
          raise ActiveRecord::Rollback
        end
      end

      @event.errors.empty?
    end

    # Accepts either an array of integer child event IDs or an array of hashes:
    # [{ child_event_id: 1, position: 0, role: "Keynote", featured: true }, ...]
    def sync_children(raw_entries)
      return true if raw_entries.nil?

      entries = normalize_child_entries(raw_entries)
      return false if @event.errors.any?

      child_ids = entries.pluck(:child_event_id)
      existing_child_ids = Event.where(id: child_ids).ids
      missing_ids = child_ids - existing_child_ids
      if missing_ids.any?
        @event.errors.add(:base, I18n.t("models.event_membership.child_not_found", ids: missing_ids.join(", ")))
        return false
      end

      current_memberships = @event.child_event_memberships.index_by(&:child_event_id)
      to_remove = current_memberships.keys - child_ids

      ActiveRecord::Base.transaction(requires_new: true) do
        if to_remove.any?
          @event.child_event_memberships.where(child_event_id: to_remove).destroy_all
        end

        entries.each_with_index do |entry, index|
          membership = current_memberships[entry[:child_event_id]] ||
            @event.child_event_memberships.build(child_event_id: entry[:child_event_id])
          membership.position = entry.key?(:position) ? entry[:position] : index
          membership.role = entry[:role] if entry.key?(:role)
          membership.featured = entry[:featured] if entry.key?(:featured)

          next if membership.save

          copy_errors(membership)
          raise ActiveRecord::Rollback
        end
      end

      @event.errors.empty?
    end

    private

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
