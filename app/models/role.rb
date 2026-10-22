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

  # A Role record can itself be a rolify resource, so a user can hold
  # single_resource_admin on one specific role (for example base_subscriber)
  # without holding it on any other role.
  #
  # The association is not named :roles (rolify's default) to avoid
  # confusion with users' roles.  restrict_with_error keeps a role from being
  # destroyed while roles are scoped to it: rolify destroys a role when its
  # last user loses it (Rolify.remove_role_if_empty), which would otherwise
  # drop every scoped grant on that role.
  resourcify :scoped_roles, dependent: :restrict_with_error

  # Returns a somewhat friendly name for the resource related to a given role.
  # In the case of Tag Moderators, a resource_type is not present, so we use the
  # resource_id to grab the specific Tag related to that moderator's role.
  # For a role scoped to a specific Role record, this is that role's name.
  def resource_name
    return resource_type unless resource_id
    return resource&.name if resource_type == "Role"

    Tag.find(resource_id).name
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
end
