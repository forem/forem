class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
             polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: {
              in: %w(
                super_admin
                admin
                tag_moderator
                trusted
                banned
                warned
                analytics_beta_tester
                switch_between_orgs
                triple_unicorn_member
                level_4_member
                level_3_member
                level_2_member
                level_1_member
                workshop_pass
                video_permission
                chatroom_beta_tester
                banned_from_mentorship
              ),
            }
  scopify
end
