module Admin
  class DataCounts
    Response = Struct.new(
      :open_abuse_reports_count,
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

      flags = Reaction
        .includes(:user, :reactable)
        .where(status: "valid")
        .live_reactable
        .where(category: "vomit")
      Response.new(
        open_abuse_reports_count: open_abuse_reports_count,
        flags_count: flags.size,
        flags_posts_count: flags.where(reactable_type: "Article").size,
        flags_comments_count: flags.where(reactable_type: "Comment").size,
        flags_users_count: flags.where(reactable_type: "User").size,
      )
    end
  end
end
