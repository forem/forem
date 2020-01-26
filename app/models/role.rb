class Role < ApplicationRecord
  ROLES = %w[
    admin
    banned
    chatroom_beta_tester
    comment_banned
    podcast_admin
    pro
    single_resource_admin
    super_admin
    tag_moderator
    mod_relations_admin
    tech_admin
    trusted
    warned
    workshop_pass
  ].freeze

  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
             polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: { in: ROLES }

  scopify
end
