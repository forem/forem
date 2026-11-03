class Role < ApplicationRecord
  ROLES = %w[
    admin
    codeland_admin
    comment_suspended
    creator
    super_moderator
    podcast_admin
    restricted_liquid_tag
    single_resource_admin
    super_admin
    support_admin
    suspended
    spam
    subforem_moderator
    tag_moderator
    tech_admin
    trusted
    warned
    limited
    base_subscriber
    impending_base_subscriber_cancellation
    community_leader_level_1
    community_leader_level_2
  ].freeze

  ROLES.each do |role|
    define_method(:"#{role}?") do
      name == role
    end
  end

  has_and_belongs_to_many :users, join_table: :users_roles # rubocop:disable Rails/HasAndBelongsToMany

  belongs_to :resource,
             polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: { in: ROLES }

  scopify

  # Returns a somewhat friendly name for the resource related to a given role:
  # the resource type for class-wide roles (e.g. "Badge"), or a display name for
  # the specific record an instance-scoped role belongs to (a Tag's name, a
  # Podcast's title, a Subforem's domain, ...). Never raises for a deleted record.
  def resource_name
    return resource_type unless resource_id
    # Rolify always stores a resource_type; this only covers legacy rows without one,
    # which were tag moderator roles.
    return Tag.find_by(id: resource_id)&.name unless resource_type

    resource_display_name || "#{resource_type} ##{resource_id}"
  end

  def name_labelize
    if single_resource_admin?
      Constants::Role::SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.detect do |_k, v|
        v[:name] == "single_resource_admin" && v[:resource_type] == resource_type
      end&.first || name
    else
      name
    end
  end

  private

  def resource_display_name
    case resource
    # Subforem#name comes from site settings, not a stored column; the domain is unique.
    when Subforem then resource.domain
    else resource.try(:name)
    end
  end
end
