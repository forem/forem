class Role < ApplicationRecord
  ROLES = %w[
    admin
    chatroom_beta_tester
    codeland_admin
    comment_suspended
    mod_relations_admin
    podcast_admin
    restricted_liquid_tag
    single_resource_admin
    super_admin
    support_admin
    suspended
    tag_moderator
    tech_admin
    trusted
    warned
    workshop_pass
  ].freeze

  has_and_belongs_to_many :users, join_table: :users_roles # rubocop:disable Rails/HasAndBelongsToMany

  belongs_to :resource,
             polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: { in: ROLES }

  scopify

  # Returns a somewhat friendly name for the resource related to a given role.
  # In the case of Tag Moderators, a resource_type is not present, so we use the
  # resource_id to grab the specific Tag related to that moderator's role.
  def resource_name
    return resource_type unless resource_id

    Tag.find(resource_id).name
  end
end
