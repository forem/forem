namespace :temporary do
  desc "Resave all articles and comments"
  task resave_all_articles_and_comments: :environment do
    if ENV["FOREM_CONTEXT"] == "forem_cloud"
      Article.find_each(&:save)
      Comment.find_each(&:save)
    end
  end
end
