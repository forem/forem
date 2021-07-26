module Search
  class UserSerializer < ApplicationSerializer
    HASH_TRANSFORM = ->(key, value) { { name: key, value: value } }

    attributes :id,
               :available_for,
               :comments_count,
               :badge_achievements_count,
               :employer_name,
               :hotness_score,
               :last_comment_at,
               :mostly_work_with,
               :name,
               :path,
               :public_reactions_count,
               :profile_image_90,
               :reactions_count,
               :username

    attribute :roles do |user|
      user.roles.map(&:name)
    end

    attribute :profile_fields do |user|
      user.profile&.data&.map(&HASH_TRANSFORM)
    end
  end
end
