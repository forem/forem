namespace :counters do
  task update_users: :environment do
    ActiveRecord::Base.transaction do
      # NOTE: we could bypass Rails by using SQL directly to compute the counts and update these columns
      User.includes(:counters).find_each do |user|
        user.build_counters unless user.counters

        relation = user.comments

        user.counters.comments_these_7_days = relation.where("created_at > ?", 7.days.ago).size
        user.counters.comments_prior_7_days = relation.
          where("created_at > ? AND created_at < ?", 14.days.ago, 7.days.ago).
          size

        user.counters.save!
      end
    end
  end
end
