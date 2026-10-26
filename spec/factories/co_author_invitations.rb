FactoryBot.define do
  factory :co_author_invitation do
    article
    user

    # Only followers of the author can be invited.
    before(:create) do |invitation|
      author = invitation.article.user
      invitation.user.follow(author) unless invitation.user.following?(author)
    end

    trait :accepted do
      status { "accepted" }
      responded_at { Time.current }

      after(:create) do |invitation|
        article = invitation.article
        article.update_columns(co_author_ids: article.co_author_ids | [invitation.user_id])
      end
    end

    trait :declined do
      status { "declined" }
      responded_at { Time.current }
    end
  end
end
