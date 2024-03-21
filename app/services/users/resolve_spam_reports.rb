module Users
  class ResolveSpamReports
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      relation = FeedbackMessage.where(status: "Open", category: "spam")

      # profile reports by url and by path
      profile_reports = relation.where(reported_url: [URL.url(user.path), user.path])
      profile_reports.update_all(status: "Resolved")

      # articles can be reported by url or by path
      article_paths = user.articles.map(&:path)
      article_paths += article_paths.map { |p| URL.url(p) }
      article_reports = relation.where(reported_url: article_paths)
      article_reports.update_all(status: "Resolved")

      # comments can be reported by url or by path
      comment_paths = user.comments.map(&:path)
      comment_paths += comment_paths.map { |p| URL.url(p) }
      comment_reports = relation.where(reported_url: comment_paths)
      comment_reports.update_all(status: "Resolved")
    end

    private

    attr_reader :user
  end
end
