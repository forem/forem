module DataUpdateScripts
  class ResaveAllCommentMentionedArticles
    def run
      # Resave all Articles that previously relied upon the `.comment-mentioned-user` CSS,
      # which was renamed in https://github.com/forem/forem/pull/13263 to `.mentioned-user`.
      Article.published.find_each(&:save)
    end
  end
end
