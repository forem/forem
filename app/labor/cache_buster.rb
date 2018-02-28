class CacheBuster

  def bust(path)
    request = HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}",
    :headers => { 'Fastly-Key' => 'f15066a3abedf47238b08e437684c84f' } )
    request = HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}?i=i",
    :headers => { 'Fastly-Key' => 'f15066a3abedf47238b08e437684c84f' } )
    return request
  end

  def bust_comment(comment)
    if comment.commentable.featured_number.to_i > (Time.now.to_i - 5.hours.to_i)
      bust("/")
      bust("/?i=i")
      bust("?i=i")
    end
    if comment.commentable.decorate.cached_tag_list_array.include?("discuss") &&
        comment.commentable.featured_number.to_i > (Time.now.to_i - 35.hours.to_i)
      bust("/")
      bust("/?i=i")
      bust("?i=i")
    end
    bust("#{comment.commentable.path}/comments/")
    bust("#{comment.commentable.path}")
    comment.commentable.comments.each do |c|
      bust(c.path)
      bust(c.path+"?i=i")
    end
    bust("#{comment.commentable.path}/comments/*")
    bust("/#{comment.user.username}")
    bust("/#{comment.user.username}/comments")
    bust("/#{comment.user.username}/comments?i=i")
    bust("/#{comment.user.username}/comments/?i=i")
  end

  def bust_article(article)
    bust("/" + article.user.username)
    bust(article.path + "/")
    bust(article.path + "?i=i")
    bust(article.path + "/?i=i")
    bust(article.path + "/comments")
    bust(article.path + "?preview=" + article.password)
    if article.organization.present?
      bust("/#{article.organization.slug}")
    end
    if article.featured_number.to_i > Time.now.to_i
      bust("/")
      bust("?i=i")
    end
    begin
      if article.published_at.to_i > 3.minutes.ago.to_i
        article.tag_list.each do |tag|
          bust("/t/#{tag}")
        end
      end
      if article.collection
        article.collection.articles.each do |a|
          bust(a.path)
        end
      end
    rescue
      puts "Tag issue"
    end
  end
end
