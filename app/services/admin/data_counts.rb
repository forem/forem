module Admin
  class DataCounts
    Response = Struct.new(
      :open_abuse_reports_count,
      :possible_spam_users_count,
      :flags_count,
      :flags_posts_count,
      :flags_comments_count,
      :flags_users_count,
      keyword_init: true,
    )

    # @return [Admin::DataCounts::Response]
    def self.call
      # If this class is to be re-used in more situations, we could pass in params
      # to dictate which counts are needed, to reduce unneeded queries.

      open_abuse_reports_count =
        FeedbackMessage.open_abuse_reports.size

      possible_spam_users_count = User.registered.where("length(name) > ?", 30)
        .where("created_at > ?", 48.hours.ago)
        .order(created_at: :desc)
        .select(:username, :name, :id)
        .where.not("username LIKE ?", "%spam_%")
        .size

      flags = Reaction
        .includes(:user, :reactable)
        .privileged_category
      Response.new(
        open_abuse_reports_count: open_abuse_reports_count,
        possible_spam_users_count: possible_spam_users_count,
        flags_count: flags.size,
        flags_posts_count: flags.where(reactable_type: "Article").size,
        flags_comments_count: flags.where(reactable_type: "Comment").size,
        flags_users_count: flags.where(reactable_type: "User").size,
      )
    end
  end
end
