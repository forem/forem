module DataUpdateScripts
  class ResaveArticlesForCodeSnippetFullscreenIcon
    def run
      # We need to regenerate the markdown for code snippets
      # See https://github.com/forem/forem/issues/11747#issuecomment-753620156
      # Article.published.find_each(&:save)
    end
  end
end
