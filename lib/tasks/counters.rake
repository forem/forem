namespace :counters do
  task update_users: :environment do
    ActiveRecord::Base.transaction do
      # NOTE: we could bypass Rails by using SQL directly to compute the counts and update these columns
      User.includes(:counters).find_each do |user|
        user.build_counters unless user.counters

        user.counters.comments_7_days = user.comments.where("created_at > ?", 7.days.ago).size
        user.counters.save!
      end
    end
  end
end
