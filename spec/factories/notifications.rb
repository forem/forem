FactoryBot.define do
  factory :notification do
    user
    organization
    notifiable { association :article }
  end

  # should these traits each be their own factory instead with sub-traits?
  # erring on side of least complexity for now

  # the less the actual service needs to run in order to notify, the faster specs will run overall

  # A factory object will carry the reality of the notification's history up until that point.
  # So if we have to test a notif for the fourth reaction on something, it helps to have a factory
  # that already has jsonb representing three existing reactions

  trait :for_follow do
    after(:create) do |notification|
      notification.update_columns(
        action: "Follow",
        created_at: DateTime.now,
        json_data:
          # Most recent follower
          { "user" =>
            { "id" => notification.notifiable.follower.id,
              "name" => notification.notifiable.follower.name,
              "path" => "/isiahebert",
              "class" => { "name" => "User" },
              "username" => notification.notifiable.follower.username,
              "created_at" => notification.notifiable.follower.created_at,
              "comments_count" => 0,
              "profile_image_90" => notification.notifiable.follower.profile_image_90 },
            # Aggregated followers
            "aggregated_siblings" => [
              { "id" => notification.notifiable.follower.id,
                "name" => notification.notifiable.follower.name,
                "path" => "/isiahebert",
                "class" => { "name" => "User" },
                "username" => notification.notifiable.follower.username,
                "created_at" => notification.notifiable.follower.created_at,
                "comments_count" => 0,
                "profile_image_90" => notification.notifiable.follower.profile_image_90 },
            ] },
        notifiable_id: notification.notifiable.id,
        notifiable_type: "Follow",
        notified_at: DateTime.now,
        organization_id: nil,
        read: false,
        updated_at: DateTime.now,
        # User being followed
        user_id: notification.notifiable.followable.id,
      )
    end
  end

  trait :for_reaction do
    after(:create) do |notification|
      notification.update_columns(
        action: "Reaction",
        created_at: DateTime.now,
        json_data:
          # most recent user and their reaction in detail
          { "user" =>
            { "id" => 6,
              "name" => "Isiah \"The Isiah\" Ebert  \\:/",
              "path" => "/isiahebert",
              "class" => { "name" => "User" },
              "username" => "isiahebert",
              "created_at" => "2023-05-12T15:16:42.478Z",
              "comments_count" => 0,
              # rubocop:disable Lint/DuplicateHashKey
              "created_at" => "2023-05-12T15:16:42.478Z",
              "comments_count" => 0,
              # rubocop:enable Lint/DuplicateHashKey
              "profile_image_90" => "/uploads/user/profile_image/6/54182c19-4280-4a92-9bcd-32c157c26ac3.png" },
            "reaction" =>
              { "category" => "exploding_head",
                "reactable" => { "path" => "/sipesmaurice/secondposting-28o7",
                                 "class" => { "name" => "Article" },
                                 "title" => "Secondposting" },
                "updated_at" => "2023-08-09T18:22:50.518Z",
                "reactable_id" => 3,
                "reactable_type" => "Article",
                # aggregated past reacting users and their reactions
                "aggregated_siblings" => [
                  { "user" =>
                    { "id" => 6,
                      "name" => "Isiah \"The Isiah\" Ebert  \\:/",
                      "path" => "/isiahebert",
                      "class" => { "name" => "User" },
                      "username" => "isiahebert",
                      "created_at" => "2023-05-12T15:16:42.478Z",
                      "comments_count" => 0,
                      "profile_image_90" => "/uploads/user/profile_image/6/54182c19-4280-4a92-9bcd-32c157c26ac3.png" },
                    "category" => "exploding_head",
                    "created_at" => "2023-08-09T18:22:50.518Z" },
                  { "user" =>
                    { "id" => 6,
                      "name" => "Isiah \"The Isiah\" Ebert  \\:/",
                      "path" => "/isiahebert",
                      "class" => { "name" => "User" },
                      "username" => "isiahebert",
                      "created_at" => "2023-05-12T15:16:42.478Z",
                      "comments_count" => 0,
                      "profile_image_90" => "/uploads/user/profile_image/6/54182c19-4280-4a92-9bcd-32c157c26ac3.png" },
                    "category" => "like",
                    "created_at" => "2023-08-09T18:22:49.268Z" },
                  { "user" =>
                    { "id" => 1,
                      "name" => "Trudi \"The Trudi\" Kemmer  \\:/",
                      "path" => "/kemmertrudi",
                      "class" => { "name" => "User" },
                      "username" => "kemmertrudi",
                      "created_at" => "2023-05-12T15:16:41.416Z",
                      "comments_count" => 4,
                      "profile_image_90" => "/uploads/user/profile_image/1/b351b3c4-bed1-4402-bccd-7475b190ce9e.png" },
                    "category" => "like",
                    "created_at" => "2023-05-15T17:43:47.076Z" },
                ] } },
        # Target of the reactions
        notifiable_id: 3,
        notifiable_type: "Article",
        notified_at: DateTime.now,
        organization_id: nil,
        read: false,
        updated_at: DateTime.now,
        # User being reacted to
        user_id: 2,
      )
    end
  end

  trait :for_bookmark do
    after(:create) do |notification|
      notification.update_columns(
        action: "Bookmark",
        created_at: DateTime.now,
        json_data:
          # Most recent bookmarker info.
          # We could also use `Notifications.user_data(create(:user))` to streamline this,
          # laying it out in full in this commit for clarity
          { "user" =>
            { "id" => 6,
              "name" => "Isiah \"The Isiah\" Ebert  \\:/",
              "path" => "/isiahebert",
              "class" => { "name" => "User" },
              "username" => "isiahebert",
              "created_at" => "2023-05-12T15:16:42.478Z",
              "comments_count" => 0,
              "profile_image_90" => "/uploads/user/profile_image/6/54182c19-4280-4a92-9bcd-32c157c26ac3.png" },
            # Aggregated bookmarkers
            "aggregated_siblings" => [
              { "id" => 6,
                "name" => "Isiah \"The Isiah\" Ebert  \\:/",
                "path" => "/isiahebert",
                "class" => { "name" => "User" },
                "username" => "isiahebert",
                "created_at" => "2023-05-12T15:16:42.478Z",
                "comments_count" => 0,
                "profile_image_90" => "/uploads/user/profile_image/6/54182c19-4280-4a92-9bcd-32c157c26ac3.png" },
            ] },
        notifiable_id: 41,
        notifiable_type: "Follow",
        notified_at: DateTime.now,
        organization_id: nil,
        read: false,
        updated_at: DateTime.now,
        # User being followed
        user_id: 7,
      )
    end
  end
end

# transient space good for eg adding a bunch of serialized reactions into a notif before saving

# "Notification...without_delay" work living in trait space?
