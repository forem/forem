module DataUpdateScripts
  class ResaveAllCommentMentionedComments
    def run
      # Resave all Comments that previously relied upon the `.comment-mentioned-user` CSS,
      # which was renamed in https://github.com/forem/forem/pull/13263 to `.mentioned-user`.
      Comment.find_each(&:save)
    end
  end
end
