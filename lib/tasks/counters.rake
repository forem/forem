namespace :counters do
  desc "Update users counters"
  task :update_users, [:batch_size] => :environment do |_t, args|
    batch_size = args.fetch(:batch_size, 1000).to_i

    # NOTE: we could bypass Rails by using SQL directly to compute the counts and update these columns
    User.includes(:counters).select(:id).find_each(batch_size: batch_size) do |user|
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
