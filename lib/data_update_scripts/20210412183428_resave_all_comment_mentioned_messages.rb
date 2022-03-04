module DataUpdateScripts
  class ResaveAllCommentMentionedMessages
    def run
      # Resave all Messages that previously relied upon the `.comment-mentioned-user` CSS,
      # which was renamed in https://github.com/forem/forem/pull/13263 to `.mentioned-user`.
      Message.find_each(&:save)
    end
  end
end
