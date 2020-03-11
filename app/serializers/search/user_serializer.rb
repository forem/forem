module Search
  class UserSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id,
               :available_for,
               :comments_count,
               :employer_name,
               :hotness_score,
               :mostly_work_with,
               :name,
               :path,
               :positive_reactions_count,
               :profile_image_90,
               :reactions_count,
               :username
  end
end
