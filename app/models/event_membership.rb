class EventMembership < ApplicationRecord
  MAX_DEPTH = 5
  MAX_ROLE_LENGTH = 64

  belongs_to :parent_event, class_name: "Event", inverse_of: :child_event_memberships
  belongs_to :child_event, class_name: "Event", inverse_of: :parent_event_memberships

  scope :ordered, -> { order(:position, :id) }

  before_validation :normalize_role

  validates :child_event_id,
            uniqueness: {
              scope: :parent_event_id,
              message: ->(_object, _data) { I18n.t("models.event_membership.already_member") }
            }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :role, length: { maximum: MAX_ROLE_LENGTH }, allow_blank: true
  validates :featured, inclusion: { in: [true, false] }

  validate :cannot_belong_to_self
  validate :no_hierarchy_cycle_or_excessive_depth

  after_commit :purge_related_events_cache, on: %i[create update destroy]

  def self.ancestor_depths_for(event_id, max_depth: MAX_DEPTH + 1)
    return {} if event_id.blank?

    sql = sanitize_sql_array([<<~SQL.squish, event_id.to_i, max_depth.to_i])
      WITH RECURSIVE ancestors(event_id, depth, path) AS (
        SELECT parent_event_id, 1, ARRAY[child_event_id, parent_event_id]
        FROM event_memberships
        WHERE child_event_id = ?
        UNION ALL
        SELECT em.parent_event_id, a.depth + 1, a.path || em.parent_event_id
        FROM event_memberships em
        INNER JOIN ancestors a ON em.child_event_id = a.event_id
        WHERE a.depth < ? AND NOT (em.parent_event_id = ANY(a.path))
      )
      SELECT event_id, MAX(depth) AS max_depth
      FROM ancestors
      GROUP BY event_id
    SQL

    connection.select_rows(sql).each_with_object({}) do |(id, depth), map|
      map[id.to_i] = depth.to_i
    end
  end

  def self.descendant_depths_for(event_id, max_depth: MAX_DEPTH + 1)
    return {} if event_id.blank?

    sql = sanitize_sql_array([<<~SQL.squish, event_id.to_i, max_depth.to_i])
      WITH RECURSIVE descendants(event_id, depth, path) AS (
        SELECT child_event_id, 1, ARRAY[parent_event_id, child_event_id]
        FROM event_memberships
        WHERE parent_event_id = ?
        UNION ALL
        SELECT em.child_event_id, d.depth + 1, d.path || em.child_event_id
        FROM event_memberships em
        INNER JOIN descendants d ON em.parent_event_id = d.event_id
        WHERE d.depth < ? AND NOT (em.child_event_id = ANY(d.path))
      )
      SELECT event_id, MAX(depth) AS max_depth
      FROM descendants
      GROUP BY event_id
    SQL

    connection.select_rows(sql).each_with_object({}) do |(id, depth), map|
      map[id.to_i] = depth.to_i
    end
  end

  private

  def normalize_role
    cleaned = role.to_s.squish
    self.role = cleaned.presence
  end

  def cannot_belong_to_self
    return if parent_event_id.blank? || child_event_id.blank?
    return unless parent_event_id == child_event_id

    errors.add(:child_event_id, I18n.t("models.event_membership.cannot_belong_to_self"))
  end

  def no_hierarchy_cycle_or_excessive_depth
    return if parent_event_id.blank? || child_event_id.blank? || parent_event_id == child_event_id
    return unless new_record? || will_save_change_to_parent_event_id? || will_save_change_to_child_event_id?

    ancestor_depths = self.class.ancestor_depths_for(parent_event_id)
    if ancestor_depths.key?(child_event_id)
      errors.add(:child_event_id, I18n.t("models.event_membership.would_create_cycle"))
      return
    end

    descendant_depths = self.class.descendant_depths_for(child_event_id)
    if descendant_depths.key?(parent_event_id)
      errors.add(:child_event_id, I18n.t("models.event_membership.would_create_cycle"))
      return
    end

    max_above = ancestor_depths.values.max || 0
    max_below = descendant_depths.values.max || 0
    return unless (max_above + 1 + max_below) > MAX_DEPTH

    errors.add(:base, I18n.t("models.event_membership.max_depth_exceeded", max: MAX_DEPTH))
  end

  def purge_related_events_cache
    event_ids = [
      parent_event_id,
      child_event_id,
      previous_changes.dig("parent_event_id", 0),
      previous_changes.dig("child_event_id", 0),
    ].compact.uniq

    return if event_ids.empty?

    Event.where(id: event_ids).find_each(&:purge_hierarchy_edge_cache!)
  end
end
