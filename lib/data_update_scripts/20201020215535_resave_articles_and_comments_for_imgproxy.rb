module DataUpdateScripts
  class ResaveArticlesAndCommentsForImgproxy
    def run
      # return unless ENV["FOREM_CONTEXT"] == "forem_cloud"
      #
      # Article.find_each(&:save)
      # Comment.find_each(&:save)
    end
  end
end
