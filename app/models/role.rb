class Role < ApplicationRecord
  ROLES = {
    admin: "admin",
    codeland_admin: "codeland_admin",
    comment_suspended: "comment_suspended",
    creator: "creator",
    mod_relations_admin: "mod_relations_admin",
    super_moderator: "super_moderator",
    podcast_admin: "podcast_admin",
    restricted_liquid_tag: "restricted_liquid_tag",
    single_resource_admin: "single_resource_admin",
    super_admin: "super_admin",
    support_admin: "support_admin",
    suspended: "suspended",
    tag_moderator: "tag_moderator",
    tech_admin: "tech_admin",
    trusted: "trusted",
    warned: "warned",
    workshop_pass: "workshop_pass"
  }.freeze

  ROLES.each do |key, value|
    define_method("#{key}?") do
      name == value
    end
  end

  has_and_belongs_to_many :users, join_table: :users_roles # rubocop:disable Rails/HasAndBelongsToMany

  belongs_to :resource,
             polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: { in: ROLES.values }

  scopify

  # Returns a somewhat friendly name for the resource related to a given role.
  # In the case of Tag Moderators, a resource_type is not present, so we use the
  # resource_id to grab the specific Tag related to that moderator's role.
  def resource_name
    return resource_type unless resource_id

    Tag.find(resource_id).name
  end
end
